source('https://rubygems.org')

gemspec

gem 'danger', '~> 8.0'
gem 'danger-rubocop', '~> 0.6'

gem 'codecov', require: false
gem 'webmock', require: false
gem 'yard'

gem 'rspec-buildkite-analytics', '~> 0.8.1'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
