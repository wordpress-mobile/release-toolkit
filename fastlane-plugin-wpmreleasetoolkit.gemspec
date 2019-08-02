# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/wpmreleasetoolkit/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-wpmreleasetoolkit'
  spec.version       = Fastlane::Wpmreleasetoolkit::VERSION
  spec.author        = 'Lorenzo Mattei'
  spec.email         = 'lore.mattei@gmail.com'

  spec.summary       = 'GitHub helper functions'
  spec.homepage      = "https://github.com/wordpress-mobile/release-toolkit"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.files << 'ext/drawText/extconf.rb'
  spec.files << Dir["bin/*"]
  spec.files << Dir["ext/*"]

  # Bring in any generated executables
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  # These files are used to generate Makefile files which in turn are used
  # to build and install the C extension.
  spec.extensions = ['ext/drawText/extconf.rb']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
  spec.add_dependency 'diffy', '~> 3.3'
  spec.add_dependency 'nokogiri', '1.10.1'
  spec.add_dependency 'octokit', '~> 4.13'
  spec.add_dependency 'git', '~> 1.3'
  spec.add_dependency 'jsonlint'
  spec.add_dependency('rake', '~> 12.3')
  spec.add_dependency('rake-compiler', '~> 1.0')
  spec.add_dependency('progress_bar', '~> 1.3')
  spec.add_dependency('parallel', '~> 1.14')
  spec.add_dependency('chroma', '0.2.0')
  spec.add_dependency('activesupport', '~> 4')

  spec.add_development_dependency('pry', '~> 0.12.2')
  spec.add_development_dependency('bundler', '~> 1.17')
  spec.add_development_dependency('rspec', '~> 3.8')
  spec.add_development_dependency('rspec_junit_formatter', '~> 0.4.1')
  spec.add_development_dependency('rubocop', '0.49.1')
  spec.add_development_dependency('rubocop-require_tools', '~> 0.1.2')
  spec.add_development_dependency('simplecov', '~> 0.16.1')
  spec.add_development_dependency('fastlane', '~> 2')
end
