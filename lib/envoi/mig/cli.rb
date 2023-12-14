require 'json'
require 'logger'
require 'optparse'

require_relative '../mig'

module Envoi

  module Mig

    class Cli

      def self.run(args = ARGV)
        options = {
          log_level: :warn,
        }

        OptionParser.new do |parser|
          parser.banner = 'Usage: envoi-mig [options] media_file_path'

          parser.on('-l', '--log-level LEVEL', 'Set log level (debug, info, warn, error, fatal)',
                    "default: #{options[:log_level]}") do |level|
            options[:log_level] = level.downcase.to_sym
          end

          parser.on('-h', '--help', 'Prints this help') do
            puts parser
            exit
          end

        end.parse!(args)

        media_file_path = args.pop

        options[:logger] = init_console_logger(options[:log_level])

        if media_file_path.nil?
          puts parser
          exit 1
        end

        media_information = Mig.run(media_file_path, options)
        puts JSON.pretty_generate(media_information)
      end

      # @param [Integer|Logger::LEVEL] log_level
      # @return Logger
      def self.init_console_logger(log_level)
        logger = Logger.new($stderr)
        logger.level = log_level
        logger
      end

    end

  end

end
