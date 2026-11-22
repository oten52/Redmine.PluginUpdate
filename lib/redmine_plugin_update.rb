# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'timeout'

module RedminePluginUpdate
  class Result
    attr_reader :message

    def initialize(ok, message)
      @ok = ok
      @message = message
    end

    def ok?
      @ok
    end

    def self.ok(message)
      new(true, message)
    end

    def self.fail(message)
      new(false, message)
    end
  end

  def self.settings
    Setting.plugin_redmine_plugin_update || {}
  end

  def self.git_plugin_ids
    ::Redmine::Plugin.all.select do |plugin|
      directory = plugin.directory.to_s
      Paths.inside_plugins?(directory) && File.directory?(File.join(directory, '.git'))
    end.map { |plugin| plugin.id.to_s }
  rescue StandardError => e
    Log.error('list', e.message)
    []
  end

  def self.cleanup_old_backups
    root = Rails.root.join('tmp', 'redmine_plugin_update_backup')
    return unless root.directory?

    cutoff = Time.now - (7 * 24 * 60 * 60)
    root.children.each do |child|
      FileUtils.rm_rf(child.to_s) if child.mtime < cutoff
    end
  rescue StandardError => e
    Log.error('cleanup', e.message)
  end
end
