module MailTool
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    class_option :server,   aliases: "-s", type: :string, desc: "IMAP server hostname"
    class_option :port,     aliases: "-p", type: :numeric, desc: "IMAP server port"
    class_option :username, aliases: "-u", type: :string, desc: "IMAP username"
    class_option :password, aliases: "-P", type: :string, desc: "IMAP password"
    class_option :ssl,      type: :boolean, desc: "Use SSL/TLS"
    class_option :config,   aliases: "-c", type: :string, desc: "Path to config file"

    desc "list", "List mail folders"
    option :filter, aliases: "-f", type: :string, desc: "Filter folders by regex pattern"
    def list
      config = build_config
      filter = parse_filter(options[:filter])

      Connection.connect(config) do |imap|
        folders = Commands::ListFolders.new(imap).call(filter: filter)

        if folders.empty?
          say "No folders found"
        else
          folders.each { |f| say f.name }
        end
      end
    rescue MailTool::Error => e
      abort_with(e.message)
    end

    desc "rename PATTERN REPLACEMENT", "Rename folders matching PATTERN"
    option :dry_run, type: :boolean, default: true, desc: "Preview changes without renaming"
    option :yes, type: :boolean, default: false, desc: "Skip confirmation"
    def rename(pattern_str, replacement)
      config = build_config
      pattern = parse_pattern(pattern_str)

      Connection.connect(config) do |imap|
        cmd = Commands::RenameFolders.new(imap, pattern: pattern, replacement: replacement)
        result = cmd.call(dry_run: true)

        if result.planned.empty?
          say "No folders match the pattern"
          return
        end

        result.planned.each do |r|
          say "#{r[:from]} -> #{r[:to]}"
        end

        if options[:dry_run]
          say "Dry run — no changes made"
          return
        end

        unless options[:yes] || yes?("Proceed with rename? (y/N) ")
          say "Cancelled"
          return
        end

        result = cmd.call(dry_run: false)
        say "Renamed #{result.renamed_count} folder(s)"
        result.errors.each do |err|
          say "Failed to rename #{err[:folder]}: #{err[:error]}"
        end
      end
    rescue MailTool::Error => e
      abort_with(e.message)
    end

    private

    def build_config
      overrides = {
        server:   options[:server],
        port:     options[:port],
        username: options[:username],
        password: options[:password],
        ssl:      options[:ssl]
      }
      config = Configuration.load(
        config_path: options[:config],
        overrides: overrides
      )
      config.validate!
      config
    end

    def parse_filter(filter_str)
      return nil unless filter_str

      Regexp.new(filter_str)
    rescue RegexpError => e
      raise MailTool::Error, "Invalid regex pattern: #{e.message}"
    end

    def parse_pattern(pattern_str)
      Regexp.new(pattern_str)
    rescue RegexpError => e
      raise MailTool::Error, "Invalid regex pattern: #{e.message}"
    end

    def abort_with(message)
      $stderr.puts "Error: #{message}"
      exit 1
    end
  end
end
