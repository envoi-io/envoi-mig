# A wrapper for the 'mediainfo' command-line tool.
class Mediainfo
  # @param [Hash] options
  # @options options [String] :mediainfo_cmd_path
  def initialize(options = {})
    @mediainfo_cmd_path = options.fetch(:mediainfo_cmd_path, '/usr/local/bin/mediainfo')
  end

  # @param [String] file_path
  def run(file_path, _options = {})
    command_line = "#{@mediainfo_cmd_path} '#{file_path}'"
    output = `#{command_line}`

    fix_encoding(output)

    parse_output_to_hash(output)
  end

  def fix_encoding(output)
    output[/test/] # Running a regexp on the string throws error if it's not UTF-8
    nil
  rescue ArgumentError
    output.force_encoding('ISO-8859-1')
    nil
  end

  # Takes the output from media info and creates a hash consisting of hashes of each 'section type'
  # Known 'section types' are: General, Video, Audio, and Menu
  #
  # @param [String] output
  def parse_output_to_hash(output)
    # Add a hash that will provide a count of sections by type
    mediainfo_hash = { 'output' => output, 'section_type_counts' => { 'audio' => 0, 'video' => 0 } }

    section_name = nil
    section_data = {}

    output.each_line do |line|
      data = line.chomp.split(':', 2)
      case data.length
      when 0 then next # Nothing parsed on this line, goto the next
      when 1
        # No key:value pair so it looks like we have a new section being defined

        # Add the previously parsed section
        append_section(mediainfo_hash, section_name, section_data) unless section_name.nil? && section_data.empty?

        section_name = data[0].strip
        section_data = {}
      when 2
        # We have a key value pair, add it to this section
        section_data[data[0].strip] = data[1].strip
      else
        # We have more than one key value pair on this line, add them all to this section
        section_data[data[0].strip] = data[1..].map(&:strip).join(':')
      end
    end
    # Append the last section we processed
    append_section(mediainfo_hash, section_name, section_data)
  end

  # Appends parsed data to the main hash by section_name
  #
  # @param [Hash] mediainfo_hash
  # @param [String|nil] section_name
  # @param [Hash] section_data
  def append_section(mediainfo_hash, section_name, section_data)
    if mediainfo_hash.key? section_name
      mediainfo_hash[section_name] = [mediainfo_hash[section_name]] unless mediainfo_hash[section_name].is_a? Array
      mediainfo_hash[section_name] << section_data
    else
      mediainfo_hash[section_name] = section_data
    end

    # Determine section type by taking the first word of the section name
    # (ex: 'Audio #1' == 'audio', 'Video' == 'video')
    section_type = begin
      (section_name.split.first || '').downcase
    rescue StandardError
      section_name
    end

    # Increment section type count for this section type
    unless mediainfo_hash['section_type_counts'].key? section_type
      mediainfo_hash['section_type_counts'][section_type] = 0
    end
    mediainfo_hash['section_type_counts'][section_type] += 1

    mediainfo_hash
  end
end
