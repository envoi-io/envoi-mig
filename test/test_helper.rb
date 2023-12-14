# frozen_string_literal: true

lib_path = File.expand_path('../lib', __dir__ || '.')
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

require 'envoi/mig'

require 'minitest/autorun'