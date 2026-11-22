# frozen_string_literal: true

module RedminePluginUpdate
  module Restart
    # A restart command that stops this process, such as docker restart,
    # may never return. A timeout is therefore not treated as failure and
    # does not revert the change.
    def self.after_success(message, rollback)
      command = configured_command
      if command.nil?
        Log.error('restart', 'restart command was rejected')
        revert(rollback, 'rejected restart command')
        return Result.fail(I18n.t(:redmine_plugin_update_failed))
      end
      if command.empty?
        return Result.ok(I18n.t(:redmine_plugin_update_manual_restart))
      end
      unless executable_available?(command)
        Log.error('restart', 'restart command is not available inside the container')
        return restart_in_process(rollback)
      end

      locale = I18n.locale
      Thread.new do
        I18n.locale = locale
        sleep 3
        failure = run(command)
        revert(rollback, failure) if failure
      end
      Result.ok(message)
    end

    def self.configured_command
      raw = RedminePluginUpdate.settings['restart_command'].to_s
      return '' if raw.strip.empty?
      return nil if raw.include?("\n") || raw.include?("\r") || raw.length > 200

      raw.strip
    end

    def self.run(command)
      stdout, stderr, status = Timeout.timeout(20) do
        Open3.capture3(command)
      end
      return nil if status.success?

      output = "#{stderr} #{stdout}".strip
      if status.exitstatus == 127 || output.match?(/not found|No such file or directory/i)
        Log.error('restart', "command did not start: #{output}")
        Log.write_status(I18n.t(:redmine_plugin_update_manual_restart))
        return nil
      end

      output
    rescue Timeout::Error
      Log.error('restart', 'command timed out; the change was left in place')
      nil
    rescue Errno::ENOENT => e
      Log.error('restart', "command not available: #{e.message}")
      Log.write_status(I18n.t(:redmine_plugin_update_manual_restart))
      nil
    rescue StandardError => e
      e.message
    end

    def self.executable_available?(command)
      exe = command.to_s.strip.split(/\s+/, 2).first.to_s
      return false unless exe =~ /\A[A-Za-z0-9._+\-\/]+\z/
      return File.executable?(exe) if exe.include?('/')

      _out, _err, status = Open3.capture3('sh', '-c', 'command -v "$1"', 'sh', exe)
      status.success?
    rescue StandardError
      false
    end

    # docker is not inside the container. Prove the new code can boot, then
    # stop this process so the container restart policy starts it again.
    def self.restart_in_process(rollback)
      ok, output = boot_test
      unless ok
        Log.error('restart', "boot test failed: #{output.to_s.slice(0, 2000)}")
        begin
          rollback.call
          Log.error('rollback', 'operation reverted')
        rescue StandardError => e
          Log.error('rollback', e.message)
        end
        return Result.fail(I18n.t(:redmine_plugin_update_boot_failed))
      end

      Thread.new do
        sleep 2
        signal_restart
      end
      Result.ok(I18n.t(:redmine_plugin_update_restarting))
    end

    def self.boot_test
      log_path = Rails.root.join('tmp', 'redmine_plugin_update_boot.txt').to_s
      FileUtils.mkdir_p(File.dirname(log_path))
      pid = Process.spawn(
        'bundle', 'exec', 'rails', 'runner', '-e', Rails.env.to_s, 'puts "BOOT OK"',
        :chdir => Rails.root.to_s,
        :out => log_path,
        :err => [:child, :out]
      )
      _pid, status = Timeout.timeout(180) { Process.wait2(pid) }
      output = File.read(log_path).to_s rescue ''
      File.delete(log_path) rescue nil
      [status.success? && output.include?('BOOT OK'), output]
    rescue Timeout::Error
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
      [false, 'boot test timed out']
    rescue StandardError => e
      [false, "#{e.class}: #{e.message}"]
    end

    def self.signal_restart
      targets = []
      targets << 1 if File.exist?('/.dockerenv')
      targets << Process.pid
      targets.uniq.each do |target|
        begin
          Process.kill('TERM', target)
          Log.error('restart', "sent TERM to #{target}")
          return
        rescue StandardError => e
          Log.error('restart', "TERM #{target}: #{e.message}")
        end
      end
    end

    def self.revert(rollback, failure)
      Log.error('restart', failure)
      rollback.call
      Log.error('rollback', 'operation reverted')
      Log.write_status(I18n.t(:redmine_plugin_update_reverted))
    rescue StandardError => e
      Log.error('rollback', e.message)
    end
  end
end
