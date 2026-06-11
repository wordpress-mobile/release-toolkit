# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/wpmreleasetoolkit/version'

Gem::Specification.new do |spec|
  spec.name          = Fastlane::Wpmreleasetoolkit::NAME
  spec.version       = Fastlane::Wpmreleasetoolkit::VERSION
  spec.author        = 'Automattic'
  spec.email         = 'mobile@automattic.com'

  spec.summary       = 'Fastlane plugin for release automation'
  spec.homepage      = 'https://github.com/wordpress-mobile/release-toolkit'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.2.2'

  spec.files = Dir['lib/**/*'] + %w[README.md LICENSE]

  # Bring in any generated executables
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
  spec.add_dependency 'buildkit', '~> 1.5'
  spec.add_dependency 'chroma', '0.2.0'
  spec.add_dependency 'diffy', '~> 3.3'
  spec.add_dependency 'dotenv', '~> 2.8'
  spec.add_dependency 'fastlane', '~> 2.237'
  spec.add_dependency 'gettext', '~> 3.5'
  spec.add_dependency 'git', '~> 1.3'
  spec.add_dependency 'java-properties', '~> 0.3.0'
  spec.add_dependency 'nokogiri', '~> 1.19', '>= 1.19.4'
  spec.add_dependency 'octokit', '~> 6.1'
  spec.add_dependency 'parallel', '~> 1.14'
  spec.add_dependency 'plist', '~> 3.1'
  spec.add_dependency 'progress_bar', '~> 1.3'
  spec.add_dependency 'rake', '>= 12.3', '< 14.0'
  spec.add_dependency 'rake-compiler', '~> 1.0'
  spec.add_dependency 'xcodeproj', '~> 1.22'

  # `google-cloud-storage` is required by fastlane, but we pin it in case it's not in the future
  spec.add_dependency 'google-cloud-storage', '~> 1.31'
end
