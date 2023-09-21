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
  raise(message)
end

# Check that the PR contains changes to the CHANGELOG.md file.
#  - If it's a feature PR, CHANGELOG should have a new entry describing the changes
#  - If it's a release PR, we expect the CHANGELOG to have been updated during `rake new_release` with updated section title + new placeholder section
unless git.modified_files.include?('CHANGELOG.md')
  warn 'Please add an entry in the CHANGELOG.md file to describe the changes made by this PR'
end

# Lint with Rubocop and report violations inline in GitHub
github.dismiss_out_of_range_messages # This way, fixed violations should go
renaming_map = (git.renamed_files || []).to_h { |e| [e[:before], e[:after]] } # when files are renamed, git.modified_files contains old name, not new one, so we need to do the convertion
rubocop.lint(
  files: git.added_files + (git.modified_files.map { |f| renaming_map[f] || f }) - git.deleted_files,
  inline_comment: true,
  fail_on_inline_comment: true # Make the inline comments failures
)
