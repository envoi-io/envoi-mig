begin
  require 'filemagic/ext'
  MEDIA_TYPE_ENABLED = true
rescue StandardError => _e
  MEDIA_TYPE_ENABLED = false
end

##
# MediaType class allows identifying media type and character set of a file.
# As a design choice, any error during file processing is silently ignored.
#
# Please note that the functionality of this class depends on MEDIA_TYPE_ENABLED constant.
# If this constant is not set or set to false, run method will always return an empty Hash.
class MediaType
  # Initializes a MediaType object.
  # Currently, it doesn't use any options provided.
  #
  # @param [Hash] options Not currently used (default: {})
  def initialize(options = {}); end

  # Determines the media type and character set of a file.
  #
  # @param [String] file_path The path to the file to scan.
  # @param [Hash] _options Not currently used (default: {})
  # @return [Hash] A hash that will be populated with type, subtype, and character set if available.
  #                The media type is split into two parts, 'type' and 'subtype',
  #                and returned as separate hash values,
  #                All exceptions are rescued, and the result is an empty Hash if an error occurs.
  def run(file_path, _options = {})
    return {} unless MEDIA_TYPE_ENABLED

    # rubocop:disable Style/RescueModifier
    media_type, charset = File.mime_type(file_path).split(';') rescue nil
    type, subtype = media_type.split('/')
    param = charset.split('=') rescue nil
    output = { type: type, subtype: subtype }
    output[param[0].strip] = param[1].strip rescue nil
    # rubocop:enable Style/RescueModifier

    output
  end
end
