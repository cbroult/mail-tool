require "openssl"

module MailTool
  class Connection
    def self.connect(config)
      if ENV["MAIL_TOOL_MOCK_IMAP"]
        require "mail_tool/testing/mock_imap"
        imap = Testing::MockImap.new(ENV["MAIL_TOOL_MOCK_IMAP"])
        return yield imap
      end

      imap = Net::IMAP.new(config.server, port: config.port, ssl: config.ssl)
      begin
        imap.login(config.username, config.password)
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
    rescue SocketError => e
      raise ConnectionError, "Failed to connect to #{config.server}: #{e.message}"
    rescue Errno::ECONNREFUSED => e
      raise ConnectionError, "Failed to connect to #{config.server}: #{e.message}"
    rescue OpenSSL::SSL::SSLError => e
      raise ConnectionError, "SSL error connecting to #{config.server}: #{e.message}"
    end
  end
end
