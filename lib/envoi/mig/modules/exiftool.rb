require 'json'
require 'shellwords'

# A wrapper for the exiftool command line tool.
class ExifTool
  def initialize(options = {})
    # @logger ||= Logger.new(STDOUT)
    @exiftool_cmd_path = options.fetch(:exiftool_cmd_path, 'exiftool')
  end

  # @param [String] file_path
  # @param [Hash] _options
  # @return [Hash]
  def run(file_path, _options = {})
    cmd_line = [@exiftool_cmd_path, '-g', '-a', '-json', file_path].shelljoin
    # @logger.debug { "[ExifTool] Executing command: #{cmd_line}" }
    metadata_json = `#{cmd_line}`
    # @logger.debug { "[ExifTool] Result: #{metadata_json}" }
    JSON.parse(metadata_json)[0]
  end
end
