# frozen_string_literal: true

module RedminePluginUpdate
  module GitCmd
    def self.repository?(directory)
      File.directory?(File.join(directory.to_s, '.git'))
    end

    def self.valid_url?(url)
      value = url.to_s
      return false if value.empty? || value.bytesize > 300
      return false if value.start_with?('-')
      return false if value =~ /[\s'"\\$;|&`<>]/
      return false if value.include?('..')
      return true if value =~ /\Ahttps:\/\/[A-Za-z0-9._~:\/?#\[\]@!$()*+,;=%-]+\z/
      return true if value =~ /\Agit@[A-Za-z0-9._-]+:[A-Za-z0-9._\/-]+\z/

      false
    end

    def self.directory_name(url)
      path = url.to_s.sub(/\.git\z/, '')
      path = path.sub(/\Agit@[^:]+:/, '')
      path = path.sub(%r{\Ahttps://[^/]+/}i, '')
      base = path.split('/').reject { |part| part.nil? || part.empty? }.last.to_s
      return nil unless base =~ /\A[A-Za-z0-9][A-Za-z0-9._-]{0,80}\z/

      base
    end

    def self.registered_id(init_file)
      return nil unless File.file?(init_file)

      text = File.read(init_file, 20_000)
      matched = text.match(/Redmine::Plugin\.register\s*\(?\s*:([a-z0-9_]+)/)
      matched && matched[1]
    rescue StandardError
      nil
    end

    def self.clone_repository(url, dest)
      capture_raw('git', 'clone', '--', url, dest)
    end

    def self.capture(directory, *args)
      capture_raw('git', '-c', "safe.directory=#{directory}", '-C', directory, *args)
    end

    def self.reset(directory, sha)
      return false unless sha.to_s =~ /\A[0-9a-f]{7,40}\z/

      _out, _err, ok = capture(directory, 'reset', '--hard', sha)
      ok
    end

    def self.capture_raw(*command)
      stdout, stderr, status = Timeout.timeout(180) do
        Open3.capture3({'GIT_TERMINAL_PROMPT' => '0'}, *command)
      end
      [Log.utf8(stdout), Log.utf8(stderr), status.success?]
    rescue SignalException, SystemExit
      raise
    rescue Exception => e
      ['', "#{e.class}: #{e.message}", false]
    end
  end
end
