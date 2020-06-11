source('https://rubygems.org')

gemspec
gem 'codecov', :require => false, :group => :test
gem "rubocop", "~> 0.75.0"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

