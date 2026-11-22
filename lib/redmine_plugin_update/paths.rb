# frozen_string_literal: true

module RedminePluginUpdate
  module Paths
    def self.plugins_root
      File.expand_path(::Redmine::Plugin.directory)
    end

    def self.inside_plugins?(path)
      return false if path.nil? || path.to_s.empty? || !File.exist?(path)

      root = plugins_root
      directory = File.realpath(path)
      prefix = root.end_with?(File::SEPARATOR) ? root : "#{root}#{File::SEPARATOR}"
      directory.start_with?(prefix) && directory != root
    rescue StandardError
      false
    end

    def self.destination_for(name)
      return nil unless name.to_s =~ /\A[A-Za-z0-9][A-Za-z0-9._-]{0,80}\z/

      root = plugins_root
      dest = File.expand_path(File.join(root, name))
      prefix = root.end_with?(File::SEPARATOR) ? root : "#{root}#{File::SEPARATOR}"
      return nil unless dest.start_with?(prefix)

      dest
    end
  end
end
