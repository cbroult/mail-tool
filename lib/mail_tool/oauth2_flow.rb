require "oauth2"
require "socket"

module MailTool
  class OAuth2Flow
    DEFAULT_REDIRECT_PORT = 8080

    def initialize(oauth2_settings)
      @settings = oauth2_settings
      @redirect_port = oauth2_settings["redirect_port"] || DEFAULT_REDIRECT_PORT
    end

    def authorization_url
      client.auth_code.authorize_url(
        redirect_uri: redirect_uri,
        scope: @settings["scope"]
      )
    end

    def exchange_code(code)
      token = client.auth_code.get_token(code, redirect_uri: redirect_uri)
      extract_tokens(token)
    end

    def refresh_token(access_token, refresh_token)
      token = OAuth2::AccessToken.from_hash(client,
                                            "access_token" => access_token,
                                            "refresh_token" => refresh_token)
      new_token = token.refresh!
      extract_tokens(new_token)
    end

    def wait_for_callback(server)
      client_socket = server.accept
      request = client_socket.gets

      code = request[/code=([^&\s]+)/, 1]

      response_body = "<html><body><h1>Authorization successful!</h1><p>You may close this window.</p></body></html>"
      client_socket.print "HTTP/1.1 200 OK\r\n"
      client_socket.print "Content-Type: text/html\r\n"
      client_socket.print "Content-Length: #{response_body.bytesize}\r\n"
      client_socket.print "Connection: close\r\n"
      client_socket.print "\r\n"
      client_socket.print response_body
      client_socket.close

      code
    ensure
      server.close
    end

    attr_reader :redirect_port

    private

    def client
      @client ||= OAuth2::Client.new(
        @settings["client_id"],
        @settings["client_secret"],
        authorize_url: @settings["authorize_url"],
        token_url: @settings["token_url"]
      )
    end

    def redirect_uri
      "http://localhost:#{@redirect_port}/callback"
    end

    def extract_tokens(token)
      {
        access_token: token.token,
        refresh_token: token.refresh_token,
        expires_at: token.expires_at
      }
    end
  end
end
