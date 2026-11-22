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
      if command.empty? || !executable_available?(command)
        Log.error('restart', 'restart command is not available inside the container') unless command.empty?
        return Result.ok(I18n.t(:redmine_plugin_update_manual_restart))
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
