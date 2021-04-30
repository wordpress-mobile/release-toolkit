def version
  lib = File.expand_path('lib', __dir__)
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
  message = %{
The version in the `Gemfile.lock` (`#{gemfile_lock_version}`) doesn't match the one in `version.rb` (`#{version}`).

Please run `bundle install` to make sure they match.
}
  fail(message)
end

# Lint with Rubocop and report violations inline in GitHub
github.dismiss_out_of_range_messages # This way, fixed violations should go
rubocop.lint(
  files: git.modified_files + git.added_files,
  inline_comment: true
)
