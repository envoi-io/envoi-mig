require 'open3'
require 'shellwords'
require 'time' # unless defined? Time

class Ffprobe
  class Movie
    attr_reader :audio_bitrate, :audio_codec, :audio_sample_rate, :audio_stream, :bitrate, :command, :colorspace,
                :creation_time, :dar, :duration, :height, :output, :par, :path, :resolution, :rotation, :sar, :time,
                :video_bitrate, :video_codec, :video_stream, :width

    def initialize(path, options = {})
      raise ArgumentError, "No such file or directory - '#{path}'" unless File.exist?(path)

      @path = path

      @ffmpeg_cmd_path = options.fetch(:ffmpeg_cmd_path, 'ffprobe')

      # ffmpeg will output to stderr
      @command = [@ffmpeg_cmd_path, '-i', path].shelljoin
      @output = Open3.popen3(command) { |_stdin, _stdout, stderr| stderr.read }

      fix_encoding(@output)

      output[/Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})/]
      @duration = (::Regexp.last_match(1).to_i * 60 * 60) + (::Regexp.last_match(2).to_i * 60) + ::Regexp.last_match(3).to_f

      output[/start: (\d*\.\d*)/]
      @time = ::Regexp.last_match(1) ? ::Regexp.last_match(1).to_f : 0.0

      output[/creation_time +: +(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/]
      @creation_time = ::Regexp.last_match(1) ? Time.parse(::Regexp.last_match(1).to_s) : nil

      output[/bitrate: (\d*)/]
      @bitrate = ::Regexp.last_match(1) ? ::Regexp.last_match(1).to_i : nil

      output[/rotate +: +(\d*)/]
      @rotation = ::Regexp.last_match(1) ? ::Regexp.last_match(1).to_i : nil

      output[/Video: (.*)/]
      @video_stream = ::Regexp.last_match(1)

      output[/Audio: (.*)/]
      @audio_stream = ::Regexp.last_match(1)

      output[/timecode .* : (.*)/]
      @timecode = ::Regexp.last_match(1)

      if video_stream.is_a? String
        # rubocop:disable Style/RescueModifier
        @video_codec, @colorspace, @resolution, video_bitrate = video_stream&.split(/\s?,\s?/)
        @video_bitrate = video_bitrate =~ %r{\A(\d+) kb/s\Z} ? ::Regexp.last_match(1).to_i : nil
        @resolution, aspect_ratios = @resolution.strip.split(' ', 2) rescue @resolution = aspect_ratios = nil
        @width, @height = @resolution.split('x') rescue @width = @height = nil
        @frame_rate = ::Regexp.last_match(1) if video_stream[/(\d*\.?\d*)\s?fps/]
        if aspect_ratios
          @dar = ::Regexp.last_match(1) if aspect_ratios[/DAR (\d+:\d+)/] rescue nil # Display Aspect Ratio = SAR * PAR
          @sar = ::Regexp.last_match(1) if aspect_ratios[/SAR (\d+:\d+)/] rescue nil # Storage Aspect Ratio = DAR/PAR
          @par = ::Regexp.last_match(1) if aspect_ratios[/PAR (\d+:\d+)/] rescue nil # Pixel aspect ratio = DAR/SAR
        end
        # rubocop:enable Style/RescueModifier

        is_widescreen?

        is_high_definition?
      end

      if audio_stream.is_a? String
        @audio_codec, audio_sample_rate, @audio_channels, _unused, audio_bitrate = audio_stream&.split(/\s?,\s?/)
        @audio_bitrate = audio_bitrate =~ %r{\A(\d+) kb/s\Z} ? ::Regexp.last_match(1).to_i : nil
        @audio_sample_rate = audio_sample_rate[/\d*/].to_i
      end

      @invalid = true if @video_stream.to_s.empty? && @audio_stream.to_s.empty?
      @invalid = true if output.include?('is not supported')
      @invalid = true if output.include?('could not find codec parameters')
    end

    # @return [Boolean]
    def valid?
      !@invalid
    end

    # @return [Boolean?]
    def is_widescreen?
      @is_widescreen ||= aspect_from_dimensions.is_a?(Numeric) ? aspect_from_dimensions > 1.4 : nil
    end
    alias is_wide_screen? is_widescreen?

    # Use width instead of height because all standard def resolutions have a width of 720 or less
    # whereas some high def resolutions have a height ~720 such as 698
    #
    # @return [Boolean]
    def is_high_definition?
      @is_high_definition ||= @width.to_i > 720
    end
    alias is_high_def? is_high_definition?

    # Will attempt to
    def calculated_aspect_ratio
      @calculated_aspect_ratio ||= aspect_from_dar || aspect_from_dimensions
    end

    # @return [Integer] File Size
    def size
      @size ||= File.size(@path)
    end

    # @return [Integer]
    def audio_channel_count(audio_channels = @audio_channels)
      return 0 unless audio_channels
      return 1 if audio_channels['mono']
      return 2 if audio_channels['stereo']
      return 6 if audio_channels['5.1']
      return 9 if audio_channels['7.2']

      # If we didn't hit a match above then find any number in #.# format and add them together to get a channel count
      audio_channels[/(\d+.?\d?).*/]
      begin
        audio_channels = ::Regexp.last_match(1).to_s.split('.').sum(&:to_i) if ::Regexp.last_match(1)
      rescue StandardError
        audio_channels
      end
      return audio_channels if audio_channels.is_a? Integer

      0
    end

    # Outputs relevant instance variables names and values as a hash
    # @return [Hash]
    def to_hash
      hash = {}
      variables = instance_variables
      %i[@ffmpeg_cmd_path @logger].each { |cmd| variables.delete(cmd) }
      variables.each do |instance_variable_name|
        hash[instance_variable_name.to_s[1..]] = instance_variable_get(instance_variable_name)
      end
      hash['audio_channel_count'] = audio_channel_count
      hash['calculated_aspect_ratio'] = calculated_aspect_ratio
      hash
    end

    protected

    # @return [Float|Integer|nil]
    def aspect_from_dar
      return @aspect_from_dar if @aspect_from_dar
      return nil unless dar

      w, h = dar&.split(':')
      aspect = w.fdiv(h)
      @aspect_from_dar = aspect.zero? ? nil : aspect
    end

    # @return [Fixed]
    def aspect_from_dimensions
      return @aspect_from_dimensions if @aspect_from_dimensions
      return nil unless width.is_a?(Numeric) && height.is_a?(Numeric)

      aspect = width&.fdiv(height) rescue nil # rubocop:disable Style/RescueModifier
      @aspect_from_dimensions = aspect.nan? ? nil : aspect
    end

    # @param [String] output
    def fix_encoding(output)
      output[/test/] # Running a regexp on the string throws error if it's not UTF-8
    rescue ArgumentError
      output.force_encoding('ISO-8859-1')
    end
  end

  # @param [Hash] options
  # @option options [String] :ffmpeg_cmd_path
  def initialize(options = {})
    @ffmpeg_cmd_path = options.fetch(:ffmpeg_cmd_path, 'ffmpeg')
  end

  # @param [String] file_path
  # @param [Hash] options
  # @option options [String] :ffmpeg_cmd_path
  def run(file_path, options = {})
    options = { ffmpeg_cmd_path: @ffmpeg_cmd_path }.merge(options)
    Movie.new(file_path, options).to_hash
  end
end
