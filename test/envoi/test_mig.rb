# frozen_string_literal: true

require_relative '../test_helper'

class TestEnvoiTestMig < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Envoi::Mig::VERSION
  end

  # Handles the case where the file is not found

  # Handles bad exiftool executable path

  # Handles bad ffmpeg executable path

  # Handles bad mediainfo executable path

  # Handles good URL as media file path

  # Handles bad URL as media file path

  # Handles file path with spaces

  # Handles file path with unicode characters

  # Handles file path with unicode characters and spaces

end
