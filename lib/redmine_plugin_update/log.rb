# frozen_string_literal: true

module RedminePluginUpdate
  module Log
    def self.error(action, message)
      line = "[PluginUpdate] #{action}: #{message}"
      Rails.logger.error(line)
      begin
        File.open(Rails.root.join('log', 'redmine_plugin_update.log'), 'a') do |file|
          file.puts("#{Time.now.utc.iso8601} #{line}")
        end
      rescue StandardError
        nil
      end
    end

    def self.write_status(text)
      File.write(status_path, text.to_s.slice(0, 500))
    rescue StandardError => e
      error('status', e.message)
    end

    def self.consume_status
      return nil unless File.file?(status_path)

      text = File.read(status_path)
      File.delete(status_path)
      text
    rescue StandardError
      nil
    end

    def self.status_path
      Rails.root.join('tmp', 'redmine_plugin_update_status.txt')
    end
  end
end
