module MailTool
  class TokenStore
    EXPIRY_BUFFER = 60

    attr_reader :path

    def self.token_key(server, username)
      "#{server}/#{username}"
    end

    def initialize(path)
      @path = File.expand_path(path)
    end

    def save(key, access_token:, refresh_token:, expires_at:)
      data = load_all
      data[key] = {
        "access_token" => access_token,
        "refresh_token" => refresh_token,
        "expires_at" => expires_at
      }
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, YAML.dump(data))
      File.chmod(0o600, @path)
    end

    def load(key)
      data = load_all
      data[key]
    end

    def expired?(tokens)
      expires_at = tokens["expires_at"]
      return true unless expires_at

      Time.now.to_i + EXPIRY_BUFFER >= expires_at
    end

    private

    def load_all
      return {} unless File.exist?(@path)

      YAML.safe_load_file(@path, permitted_classes: [Symbol]) || {}
    end
  end
end
