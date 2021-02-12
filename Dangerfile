def version
  lib = File.expand_path('../lib', __FILE__)
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
  require 'fastlane/plugin/wpmreleasetoolkit/version'
  Fastlane::Wpmreleasetoolkit::VERSION
end

def gemfile_lock_version
  gemfile_lock = File.read('./Gemfile.lock')
  gemfile_lock.scan(/fastlane-plugin-wpmreleasetoolkit \((\d+.\d+.\d+)\)/).last.first
end

# Before checking the version, get rid of any change that `bundle install`
# might have done.
`git checkout Gemfile.lock &> /dev/null`

if version.to_s != gemfile_lock_version.to_s
  message = %Q{
The version in the `Gemfile.lock` (`#{gemfile_lock_version}`) doesn't match the one in `version.rb` (`#{version}`).

Please run `bundle install` to make sure they match.
}
  fail(message)
end
