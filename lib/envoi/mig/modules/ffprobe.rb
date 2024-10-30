require 'open3'
require 'shellwords'
require 'time'
require 'json'
require 'logger'

class Ffprobe
  class Movie
    attr_reader :audio_bitrate, :audio_codec, :audio_sample_rate, :audio_stream, :bitrate, :command, :colorspace,
                :creation_time, :dar, :duration, :height, :output, :par, :path, :resolution, :rotation, :sar, :time,
                :video_bitrate, :video_codec, :video_stream, :width

    def initialize(path, options = {})
      raise ArgumentError, "No such file or directory - '#{path}'" unless File.exist?(path)

      @path = path
      @ffprobe_cmd_path = options.fetch(:ffprobe_cmd_path, 'ffprobe')
      @logger = options.fetch(:logger, Logger.new($stdout))

      run_ffprobe
      parse_json_output(@output)
    end

    def valid?
      !@invalid
    end

    def is_widescreen?
      @is_widescreen ||= aspect_quotient_from_dimensions.is_a?(Numeric) ? aspect_quotient_from_dimensions > 1.4 : nil
    end
    alias is_wide_screen? is_widescreen?

    def is_high_definition?
      @is_high_definition ||= @width.to_i > 720
    end
    alias is_high_def? is_high_definition?

    def calculated_aspect_quotient
      @calculated_aspect_quotient ||= aspect_quotient_from_dar || aspect_quotient_from_dimensions
    end

    def size
      @size ||= File.size(@path)
    end

    def audio_channel_count(audio_channels = @audio_channels)
      return 0 unless audio_channels
      return 1 if audio_channels['mono']
      return 2 if audio_channels['stereo']
      return 6 if audio_channels['5.1']
      return 9 if audio_channels['7.2']

      audio_channels[/(\d+.?\d?).*/]
      begin
        audio_channels = ::Regexp.last_match(1).to_s.split('.').sum(&:to_i) if ::Regexp.last_match(1)
      rescue StandardError
        audio_channels
      end
      return audio_channels if audio_channels.is_a? Integer

      0
    end

    def to_hash
      hash = {}
      variables = instance_variables
      %i[@ffprobe_cmd_path @logger].each { |cmd| variables.delete(cmd) }
      variables.each do |instance_variable_name|
        hash[instance_variable_name.to_s[1..]] = instance_variable_get(instance_variable_name)
      end
      hash['audio_channel_count'] = audio_channel_count
      hash['calculated_aspect_quotient'] = calculated_aspect_quotient
      hash
    end

    protected

    def aspect_quotient_from_dar
      return @aspect_quotient_from_dar if @aspect_quotient_from_dar
      return nil unless dar

      w, h = dar&.split(':')&.map(&:to_i)
      aspect = w.fdiv(h)
      @aspect_quotient_from_dar = aspect.zero? ? nil : aspect
    end

    def aspect_quotient_from_dimensions
      return @aspect_quotient_from_dimensions if @aspect_quotient_from_dimensions
      return nil unless width.is_a?(Numeric) && height.is_a?(Numeric)

      aspect = width&.fdiv(height) rescue nil
      @aspect_quotient_from_dimensions = !aspect || aspect.nan? ? nil : aspect
    end

    private

    def run_ffprobe
      @command = [
        @ffprobe_cmd_path,
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        # '-i',
        @path
      ].shelljoin

      @output = Open3.popen3(@command) { |_stdin, stdout, _stderr| stdout.read }
      fix_encoding(@output)
    rescue StandardError => e
      @logger.error("Failed to run ffprobe: #{e.message}")
      @invalid = true
    end

    def parse_json_output(output_raw)
      output = JSON.parse(output_raw)
      format = output['format']
      tags = format['tags']
      video_stream = output['streams'].find { |s| s['codec_type'] == 'video' }
      audio_stream = output['streams'].find { |s| s['codec_type'] == 'audio' }

      @duration = format['duration'].to_f
      @time = format['start_time'].to_f
      @creation_time = tags['creation_time']
      @bitrate = format['bit_rate'].to_i
      @rotation = video_stream['tags']['rotate'].to_i if video_stream && video_stream['tags'] && video_stream['tags']['rotate']

      if video_stream
        @video_codec = video_stream['codec_name']
        @colorspace = video_stream['color_space']
        @resolution = "#{video_stream['width']}x#{video_stream['height']}"
        @width = video_stream['width']
        @height = video_stream['height']
        @dar = video_stream['display_aspect_ratio']
        @sar = video_stream['sample_aspect_ratio']
        @video_bitrate = video_stream['bit_rate'].to_i
        @frame_rate = video_stream['avg_frame_rate']
      end

      if audio_stream
        @audio_codec = audio_stream['codec_name']
        @audio_sample_rate = audio_stream['sample_rate'].to_i
        @audio_channels = audio_stream['channels']
        @audio_bitrate = audio_stream['bit_rate'].to_i
      end
    rescue JSON::ParserError => e
      @logger.error("Failed to parse JSON output: #{e.message}")
      @invalid = true
    end

    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding('ISO-8859-1')
    end
  end

  def initialize(options = {})
    @ffprobe_cmd_path = options.fetch(:ffprobe_cmd_path, 'ffprobe')
    @logger = options.fetch(:logger, Logger.new($stdout))
  end

  def run(file_path, options = {})
    options = { ffprobe_cmd_path: @ffprobe_cmd_path, logger: @logger }.merge(options)
    Movie.new(file_path, options).to_hash
  end
end