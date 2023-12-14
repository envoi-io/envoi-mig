# frozen_string_literal: true

require_relative '../test_helper'

class Envoi::TestMig < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Envoi::Mig::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
