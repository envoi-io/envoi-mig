# frozen_string_literal: true

require 'English'
require_relative 'mig/version'

require 'logger'
require_relative 'mig/modules/exiftool'
require_relative 'mig/modules/ffprobe'
require_relative 'mig/modules/mediainfo'
require_relative 'mig/modules/media_type'
require_relative 'mig/modules/common'

module Envoi
  module Mig

    MODULES = [
      { name: 'Exiftool', class: ExifTool, symbol: :exiftool, enabled: true },
      { name: 'FileMagic', class: MediaType, symbol: :filemagic, enabled: true },
      { name: 'FFProbe', class: Ffprobe, symbol: :ffprobe, enabled: true },
      { name: 'MediaInfo', class: Mediainfo, symbol: :mediainfo, enabled: true },
    ].freeze

    class << self
      def run(file_path, options)
        mig = Main.new(options)
        mig.run(file_path)
      end
    end

    class Main
      attr_reader :log, :options

      # @param [Hash] options_in
      # @option options [String] :exiftool_cmd_path
      # @option options [String] :ffmpeg_cmd_path
      # @option options [String] :mediainfo_cmd_path
      def initialize(options_in = {})
        @options = {}
        @options.merge!(options_in)

        @log = @options[:logger] || Logger.new($stderr)
        log.debug { "#{self.class.name} - Options loaded. #{@options}" }

        @options[:logger] ||= log

        params = @options.dup

        @exiftool = ExifTool.new(params)
        @ffprobe = Ffprobe.new(params)
        @mediainfo = Mediainfo.new(params)

        @media_typer = MediaType.new
      end

      def media_type
        @media_type ||= {}
      end

      def metadata_sources
        @metadata_sources ||= {}
      end

      def self.run(file_path, options={})
        main = new(options)
        main.run(file_path)
      end

      # @param [String] file_path The path to the file to gather information about
      def run(file_path)
        @media_type = {}
        @metadata_sources = {}

        raise ArgumentError, "File Not Found. File Path: '#{file_path}'" unless File.exist?(file_path)

        gathering_start = Time.now
        log.debug { "Gathering metadata for file: #{file_path}" }
        @metadata_sources = run_modules(file_path)
        log.debug { "Metadata gathering completed. Took: #{Time.now - gathering_start} seconds" }

        output_json = JSON.pretty_generate(metadata_sources)

        File.write(options[:output_file], output_json) if options[:output_file]

        puts output_json if options[:output_to_console]

        metadata_sources
      end

      def run_module(module_name, symbol, handler, file_path)
        log.debug { "Running #{module_name}." }
        start = Time.now
        metadata_sources[symbol.to_sym] = begin
          handler.run(file_path, options)
        rescue StandardError => e
          { error: { message: e.message, backtrace: e.backtrace } }
        end
        log.debug { "#{module_name} took #{Time.now - start}" }
      end

      # @param [String] file_path The path of the file to gather information about
      # @return [Hash]
      def run_modules(file_path)
        run_module('Filemagic', :filemagic, @media_typer, file_path)
        run_module('MediaInfo', :mediainfo, @mediainfo, file_path)
        run_module('FFProbe', :ffprobe, @ffprobe, file_path)
        run_module('ExifTool', :exiftool, @exiftool, file_path)

        set_media_type
        metadata_sources[:media_type] = media_type
        metadata_sources[:common] = Common.common_variables(metadata_sources)
        metadata_sources
      end

      def determine_media_type_using_exiftool
        exiftool_md = metadata_sources[:exiftool]
        return unless exiftool_md.is_a?(Hash)

        mime_type = exiftool_md['MIMEType']
        return unless mime_type.is_a?(String)

        type, sub_type = mime_type.split('/')
        return unless type

        { type: type, subtype: sub_type }
      end

      def determine_media_type_using_filemagic
        filemagic_md = metadata_sources[:filemagic]
        return unless filemagic_md.is_a?(Hash)
        return unless filemagic_md[:type]

        filemagic_md
      end

      def set_media_type
        @media_type = determine_media_type_using_filemagic || determine_media_type_using_exiftool
      end
    end
  end
end
