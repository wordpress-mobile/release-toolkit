source('https://rubygems.org')

gemspec
gem "danger", "~> 8.0"

group :test do
  gem 'codecov', :require => false
  gem 'rspec'
  gem 'yard'
end

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
