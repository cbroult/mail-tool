module MailTool
  class Configuration
    DEFAULT_CONFIG_DIR = File.join(Dir.home, ".config", "mail-tool")
    DEFAULT_CONFIG_PATH = File.join(DEFAULT_CONFIG_DIR, "config.yml")
    DEFAULTS = { port: 993, ssl: true, auth_type: "basic",
                 token_store: File.join(DEFAULT_CONFIG_DIR, "tokens.yml") }.freeze
    REQUIRED = %i[server username].freeze
    OAUTH2_REQUIRED = %w[client_id client_secret authorize_url token_url].freeze

    attr_accessor :server, :port, :username, :password, :ssl,
                  :auth_type, :oauth2, :token_store

    def self.default_config_path
      File.join(Dir.home, ".config", "mail-tool", "config.yml")
    end

    def self.load(config_path: nil, overrides: {})
      config = new
      config.apply_defaults
      config.apply_file(config_path) if config_path
      config.apply_overrides(overrides)
      config
    end

    def apply_defaults
      DEFAULTS.each { |key, value| send(:"#{key}=", value) }
    end

    def apply_file(path)
      return unless File.exist?(path)

      data = YAML.safe_load_file(path, permitted_classes: [Symbol]) || {}
      data.each do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
    end

    def apply_overrides(overrides)
      overrides.each do |key, value|
        send(:"#{key}=", value) if !value.nil? && respond_to?(:"#{key}=")
      end
    end

    def validate!
      validate_required!(REQUIRED)
      if auth_type == "xoauth2"
        validate_oauth2_settings!
      else
        validate_required!(%i[password])
      end
    end

    private

    def validate_required!(fields)
      fields.each do |field|
        value = send(field)
        if value.nil? || (value.respond_to?(:empty?) && value.empty?)
          raise ConfigurationError, "#{field} is required"
        end
      end
    end

    def validate_oauth2_settings!
      OAUTH2_REQUIRED.each do |field|
        value = oauth2.is_a?(Hash) ? oauth2[field] : nil
        if value.nil? || (value.respond_to?(:empty?) && value.empty?)
          raise ConfigurationError, "oauth2.#{field} is required"
        end
      end
    end
  end
end
