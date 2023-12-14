# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'envoi/mig/version'

Gem::Specification.new do |spec|
  spec.name = 'envoi-mig'
  spec.version = Envoi::Mig::VERSION
  spec.authors = ['Envoi']
  spec.email = ['developers@envoi.io']

  spec.summary = 'Envoi Media Information Gather'
  spec.description = 'A utility common tools to gather information about a media file.'
  spec.homepage = 'https://github.com/envoi-io/envoi-mig'
  spec.license = 'MIT'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/envoi-io/envoi-mig'
  spec.metadata['changelog_uri'] = 'https://github.com/envoi-io/envoi-mig/blob/main/CHANGELOG.md'

  spec.files = Dir.glob('lib/**/*.rb') + %w[README.md LICENSE.txt]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\A#{spec.bindir}/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby-filemagic', '~> 0.7'

  spec.add_development_dependency 'minitest', '~> 5'
  spec.add_development_dependency 'rake', '~> 10'

  spec.required_ruby_version = '>= 2.6.0'
end
