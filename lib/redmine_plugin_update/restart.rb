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

      "#{stderr} #{stdout}".strip
    rescue Timeout::Error
      Log.error('restart', 'command timed out; the change was left in place')
      nil
    rescue StandardError => e
      e.message
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
