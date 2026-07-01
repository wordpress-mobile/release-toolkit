# frozen_string_literal: true

source('https://rubygems.org')

gemspec

gem 'buildkite-test_collector', '~> 2.3'
gem 'codecov', require: false
gem 'danger-dangermattic', '~> 1.0'
gem 'webmock', require: false
gem 'yard'

# Security:
# - https://github.com/lostisland/faraday/pull/1665
# - https://github.com/lostisland/faraday/pull/1681
# Faraday 2.0 is not compatible with Fastlane
gem 'faraday', '~> 1.10', '>= 1.10.6'
