# frozen_string_literal: true

source('https://rubygems.org')

gemspec

# Only needed for specs (Time.use_zone, String#to_time, Hash#slice!)
gem 'activesupport', '~> 8.1'
gem 'buildkite-test_collector', '~> 2.3'
gem 'codecov', require: false
gem 'danger-dangermattic', '~> 1.0'
# Security:
# - https://github.com/lostisland/faraday/pull/1665
# - https://github.com/lostisland/faraday/pull/1681
#
# Faraday 2.0 is not compatible with Fastlane
#
# See also:
# - https://github.com/fastlane/fastlane/issues/21334
# - https://github.com/fastlane/fastlane/pull/30089
gem 'faraday', '~> 1.10', '>= 1.10.5'
gem 'pry', '~> 0.12.2'
gem 'rmagick', '~> 5.3'
gem 'rspec', '~> 3.8'
gem 'rspec_junit_formatter', '~> 0.4.1'
gem 'rubocop', '~> 1.65'
gem 'rubocop-rspec', '3.0'
gem 'simplecov', '~> 0.16.1'
gem 'webmock', require: false
gem 'yard'
