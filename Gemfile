source('https://rubygems.org')

gemspec

gem 'danger', '~> 8.0'
gem 'danger-rubocop', '~> 0.6'

gem 'codecov', require: false
gem 'webmock', require: false, group: :test
gem 'yard'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
