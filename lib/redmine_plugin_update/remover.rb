# frozen_string_literal: true

module RedminePluginUpdate
  module Remover
    def self.remove(plugin)
      directory = plugin.directory.to_s
      unless Paths.inside_plugins?(directory)
        Log.error('remove', "refused path #{directory}")
        return Result.fail(I18n.t(:redmine_plugin_update_failed))
      end

      backup_root = Rails.root.join('tmp', 'redmine_plugin_update_backup').to_s
      FileUtils.mkdir_p(backup_root)
      backup = File.join(backup_root, "#{plugin.id}-#{Time.now.to_i}")
      begin
        FileUtils.mv(directory, backup)
      rescue StandardError => e
        Log.error('remove', e.message)
        return Result.fail(I18n.t(:redmine_plugin_update_failed))
      end

      Restart.after_success(
        I18n.t(:redmine_plugin_update_removed),
        lambda { restore(backup, directory) }
      )
    end

    def self.restore(backup, directory)
      return if File.exist?(directory)
      return unless File.exist?(backup)

      FileUtils.mv(backup, directory)
    end
  end
end
