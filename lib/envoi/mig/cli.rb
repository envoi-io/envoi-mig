require 'json'
require 'logger'
require 'optparse'

require_relative '../mig'

module Envoi

  module Mig

    class Cli

      @options = {
        log_level: :warn,
        log_to_console: :stderr,
        enabled_modules: Mig::MODULES.dup.keep_if { |m| m[:enabled] }.map { |m| m[:symbol] },
        output_to_console: true
      }

      @module_list = Mig::MODULES.map { |m| m[:symbol] }.sort

      # @param [Integer|Logger::LEVEL] log_level
      # @return Logger
      def self.init_console_logger(options = @options)
        log_device = MultiIO.new
        log_device.add_target(options[:log_to_console] == :stdout ? $stdout : $stderr) if options[:log_to_console]
        log_device.add_target(File.open(options[:log_file_path], 'a')) if options[:log_file_path]

        logger = Logger.new(log_device)
        logger.level = options[:log_level]
        logger
      end

      def self.init_parser(options = @options)
        OptionParser.new do |parser|
          parser.banner = 'Usage: envoi-mig [options] media_file_path'
          parser.on('-l', '--log-level LEVEL', 'Set log level (debug, info, warn, error, fatal)',
                    "default: #{options[:log_level]}") do |level|
            options[:log_level] = level.downcase.to_sym
          end
          parser.on('-exif', '--exif-cmd-path PATH', 'Set Exif command file path') do |path|
            options[:exiftool_cmd_path] = path
          end
          parser.on('-ffprobe', '--ffprobe-cmd-path PATH', 'Set FFProbe command file path') do |path|
            options[:ffprobe_cmd_path] = path
          end
          parser.on('-mediainfo', '--mediainfo-cmd-path PATH', 'Set MediaInfo command file path') do |path|
            options[:mediainfo_cmd_path] = path
          end
          parser.on('-e', '--enable-modules x,y,z', Array, "Enable modules (#{@module_list.join(', ')})",
                    "default: #{options[:enabled_modules].join(', ')}") do |list|
            options[:enabled_modules] = list
          end
          parser.on('--[no-]log-to-console [stdout|stderr]', 'Log to console', "default: #{options[:log_to_console]}") do |location|
            options[:log_to_console] = location.to_sym
          end
          parser.on('-L', '--log-to-file DEST', 'File path to output log entries to.') do |location|
            options[:log_file_path] = location
          end
          parser.on('-o', '--output-file PATH', 'Set output json file path') do |path|
            options[:output_file] = path
          end
          parser.on('--[no-]output-to-console', 'Output to console',
                    "default: #{options[:output_to_console]}") do |output_to_console|
            options[:output_to_console] = output_to_console
          end
          parser.on('-h', '--help', 'Prints this help') do
            puts parser
            exit
          end
        end
      end

      def self.run(args = ARGV)

        parser = init_parser
        parser.parse!(args)

        media_file_path = args.pop

        @options[:logger] = init_console_logger

        if media_file_path.nil?
          puts parser
          exit 1
        end

        Mig.run(media_file_path, @options)
      end

    end

    # rubocop:disable Style/SingleLineMethods, Style/Documentation
    class MultiIO
      def initialize(*targets); @targets = targets end
      def add_target(target); @targets << target end
      def write(*args); @targets.each { |t| t.write(*args) } end
      def close; @targets.each(&:close) end
    end
    # rubocop:enable Style/SingleLineMethods, Style/Documentation

  end

end
