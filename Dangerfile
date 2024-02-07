# frozen_string_literal: true

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

github.dismiss_out_of_range_messages

# `files: []` forces rubocop to scan all files, not just the ones modified in the PR
rubocop.lint(files: [], force_exclusion: true, inline_comment: true, fail_on_inline_comment: true, include_cop_names: true)

manifest_pr_checker.check_gemfile_lock_updated

# skip remaining checks if we're during the release process
if github.pr_labels.include?('Releases')
  message('This PR has the `Releases` label: some checks will be skipped.')
  return
end

# Before checking the version, get rid of any change that `bundle install`
# might have done.
`git checkout Gemfile.lock &> /dev/null`

if version.to_s != gemfile_lock_version.to_s
  message = <<~MESSAGE
    The version in the `Gemfile.lock` (`#{gemfile_lock_version}`) doesn't match the one in `version.rb` (`#{version}`).

    Please run `bundle install` to make sure they match.
  MESSAGE

  failure(message)
end

# Check that the PR contains changes to the CHANGELOG.md file.
#  - If it's a feature PR, CHANGELOG should have a new entry describing the changes
#  - If it's a release PR, we expect the CHANGELOG to have been updated during `rake new_release` with updated section title + new placeholder section
unless git.modified_files.include?('CHANGELOG.md')
  warn 'Please add an entry in the CHANGELOG.md file to describe the changes made by this PR'
end

labels_checker.check(
  do_not_merge_labels: ['Do Not Merge'],
  required_labels: [//],
  required_labels_error: 'PR requires at least one label.'
)

pr_size_checker.check_diff_size(max_size: 500)

milestone_checker.check_milestone_due_date(days_before_due: 5)

warn("No reviewers have been set for this PR yet. Please request a review from **@\u2060wordpress-mobile/apps-infrastructure**.") unless github_utils.requested_reviewers? || github.pr_draft?
