# frozen_string_literal: true

module RedminePluginUpdate
  module Updater
    def self.pull(plugin)
      directory = plugin.directory.to_s
      unless Paths.inside_plugins?(directory) && GitCmd.repository?(directory)
        Log.error('pull', "not a git checkout: #{directory}")
        return Result.fail(I18n.t(:redmine_plugin_update_not_git))
      end

      dirty, dirty_error, dirty_ok = GitCmd.capture(directory, 'status', '--porcelain')
      unless dirty_ok
        Log.error('pull', dirty_error)
        return Result.fail(I18n.t(:redmine_plugin_update_failed))
      end
      unless dirty.strip.empty?
        Log.error('pull', "local changes in #{directory}")
        return Result.fail(I18n.t(:redmine_plugin_update_dirty))
      end

      sha, sha_error, sha_ok = GitCmd.capture(directory, 'rev-parse', 'HEAD')
      unless sha_ok
        Log.error('pull', sha_error)
        return Result.fail(I18n.t(:redmine_plugin_update_failed))
      end
      sha = sha.strip

      out, err, ok = GitCmd.capture(directory, 'pull', '--ff-only')
      unless ok
        Log.error('pull', "#{err} #{out}")
        restore(directory, sha)
        return Result.fail(I18n.t(:redmine_plugin_update_failed))
      end

      Restart.after_success(I18n.t(:redmine_plugin_update_pulled), lambda { restore(directory, sha) })
    end

    def self.restore(directory, sha)
      return unless Paths.inside_plugins?(directory)

      GitCmd.reset(directory, sha)
    end
  end
end
