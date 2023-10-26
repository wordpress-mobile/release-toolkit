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

def finished_reviews?
  repo_name = github.pr_json['base']['repo']['full_name']
  pr_number = github.pr_json['number']

  !github.api.pull_request_reviews(repo_name, pr_number).empty?
end

def requested_reviewers?
  has_requested_reviews = !github.pr_json['requested_teams'].to_a.empty? || !github.pr_json['requested_reviewers'].to_a.empty?
  has_requested_reviews || finished_reviews?
end

return if github.pr_labels.include?('Releases')

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

manifest_pr_checker.check_gemfile_lock_updated
labels_checker.check(
  required_labels: [//],
  required_labels_error: 'PR is missing at least one label.'
)
pr_size_checker.check_diff_size
milestone_checker.check_milestone_due_date(days_before_due: 5)

github.dismiss_out_of_range_messages
rubocop.lint inline_comment: true, fail_on_inline_comment: true, include_cop_names: true

warn "No reviewers have been set for this PR yet. Please request a review from **@\u2028wordpress-mobile/apps-infrastructure**." unless requested_reviewers?
