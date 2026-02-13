require "openssl"

module MailTool
  class Connection
    def self.connect(config)
      access_token = resolve_xoauth2_token(config) if config.auth_type == "xoauth2"

      if ENV["MAIL_TOOL_MOCK_IMAP"]
        require "mail_tool/testing/mock_imap"
        imap = Testing::MockImap.new(ENV["MAIL_TOOL_MOCK_IMAP"])
        return yield imap
      end

      imap = Net::IMAP.new(config.server, port: config.port, ssl: config.ssl)
      begin
        if config.auth_type == "xoauth2"
          imap.authenticate("XOAUTH2", config.username, access_token)
        else
          imap.login(config.username, config.password)
        end
        yield imap
      rescue Net::IMAP::NoResponseError => e
        raise AuthenticationError, "Authentication failed for #{config.username}: #{e.message}"
      ensure
        begin
          imap.logout
        rescue StandardError
          nil
        end
        imap.disconnect
      end
    rescue SocketError, Errno::ECONNREFUSED => e
      raise ConnectionError, "Failed to connect to #{config.server}: #{e.message}"
    rescue OpenSSL::SSL::SSLError => e
      raise ConnectionError, "SSL error connecting to #{config.server}: #{e.message}"
    end

    def self.resolve_xoauth2_token(config)
      store = TokenStore.new(config.token_store)
      key = TokenStore.token_key(config.server, config.username)
      tokens = store.load(key)

      unless tokens
        raise ConfigurationError,
              "No OAuth2 tokens found for #{config.username}. Run 'mail-tool authorize' first."
      end

      if store.expired?(tokens)
        flow = OAuth2Flow.new(config.oauth2)
        new_tokens = flow.refresh_token(tokens["access_token"], tokens["refresh_token"])
        store.save(key, **new_tokens)
        new_tokens[:access_token]
      else
        tokens["access_token"]
      end
    end
    private_class_method :resolve_xoauth2_token
  end
end
