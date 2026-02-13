module MailTool
  class Configuration
    DEFAULTS = { port: 993, ssl: true }.freeze
    REQUIRED = %i[server username password].freeze

    attr_accessor :server, :port, :username, :password, :ssl

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
      REQUIRED.each do |field|
        value = send(field)
        if value.nil? || (value.respond_to?(:empty?) && value.empty?)
          raise ConfigurationError, "#{field} is required"
        end
      end
    end
  end
end
