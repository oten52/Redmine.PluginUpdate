# frozen_string_literal: true

module RedminePluginUpdate
  module Installer
    def self.install(url)
      value = url.to_s.strip
      unless GitCmd.valid_url?(value)
        Log.error('install', 'rejected url')
        return Result.fail(I18n.t(:redmine_plugin_update_invalid_url))
      end

      name = GitCmd.directory_name(value)
      dest = Paths.destination_for(name)
      if dest.nil?
        Log.error('install', 'rejected directory name')
        return Result.fail(I18n.t(:redmine_plugin_update_invalid_url))
      end
      if File.exist?(dest)
        Log.error('install', "directory already exists: #{dest}")
        return Result.fail(I18n.t(:redmine_plugin_update_exists))
      end

      created = false
      begin
        created = true
        out, err, ok = GitCmd.clone_repository(value, dest)
        raise "clone failed: #{err} #{out}" unless ok
        raise 'init.rb missing' unless File.file?(File.join(dest, 'init.rb'))

        plugin_id = GitCmd.registered_id(File.join(dest, 'init.rb'))
        if plugin_id && ::Redmine::Plugin.all.any? { |plugin| plugin.id.to_s == plugin_id }
          raise "plugin already installed: #{plugin_id}"
        end
      rescue StandardError => e
        Log.error('install', e.message)
        remove_failed_clone(dest) if created
        return Result.fail(failure_message(e))
      end

      Restart.after_success(I18n.t(:redmine_plugin_update_installed), lambda { remove_failed_clone(dest) })
    end

    def self.failure_message(error)
      text = error.message.to_s
      return I18n.t(:redmine_plugin_update_no_init) if text.include?('init.rb')
      return I18n.t(:redmine_plugin_update_duplicate) if text.include?('already installed')

      I18n.t(:redmine_plugin_update_failed)
    end

    def self.remove_failed_clone(dest)
      return unless Paths.destination_for(File.basename(dest)) == File.expand_path(dest)
      return unless File.exist?(dest)

      FileUtils.rm_rf(dest)
    end
  end
end
