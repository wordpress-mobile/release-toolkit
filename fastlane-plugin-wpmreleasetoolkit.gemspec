lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/wpmreleasetoolkit/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-wpmreleasetoolkit'
  spec.version       = Fastlane::Wpmreleasetoolkit::VERSION
  spec.author        = 'Lorenzo Mattei'
  spec.email         = 'lore.mattei@gmail.com'

  spec.summary       = 'GitHub helper functions'
  spec.homepage      = 'https://github.com/wordpress-mobile/release-toolkit'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.6'

  spec.files         = Dir['lib/**/*'] + Dir['ext/drawText/{makefile.example,drawText/**/*,drawText Tests/**/*,drawText.xcodeproj/**/*}'] + %w[README.md LICENSE]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.files << 'ext/drawText/extconf.rb'
  spec.files << Dir['bin/*']
  spec.files << Dir['ext/*']

  # Bring in any generated executables
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  # These files are used to generate Makefile files which in turn are used
  # to build and install the C extension.
  spec.extensions = ['ext/drawText/extconf.rb']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
  spec.add_dependency 'diffy', '~> 3.3'
  spec.add_dependency 'nokogiri', '~> 1.11' # Needed for AndroidLocalizeHelper
  spec.add_dependency 'octokit', '~> 4.18'
  spec.add_dependency 'git', '~> 1.3'
  spec.add_dependency 'jsonlint', '~> 0.3'
  spec.add_dependency 'rake', '~> 12.3'
  spec.add_dependency 'rake-compiler', '~> 1.0'
  spec.add_dependency 'progress_bar', '~> 1.3'
  spec.add_dependency 'parallel', '~> 1.14'
  spec.add_dependency 'chroma', '0.2.0'
  spec.add_dependency 'activesupport', '~> 5'
  # Some of the upstream code uses `BigDecimal.new` which version 2.0 of the
  # `bigdecimal` gem removed. Until we'll find the time to identify the
  # dependencies and see if we can move them to something compatible with
  # modern `bigdecimal`, let's constrain the gem to a version still supporting
  # `.new` but which warns about it deprecation.
  spec.add_dependency 'bigdecimal', '~> 1.4'

  spec.add_development_dependency 'pry', '~> 0.12.2'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.4.1'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'rubocop-rspec', '2.3.0'
  spec.add_development_dependency 'rubocop-require_tools', '~> 0.1.2'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
  spec.add_development_dependency 'fastlane', '~> 2'
  spec.add_development_dependency 'rmagick', '~> 4.1'
  spec.add_development_dependency 'cocoapods', '~> 1.10'
end
