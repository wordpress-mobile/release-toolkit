require 'spec_helper'
require 'shared_examples_for_update_metadata_source_action'

describe Fastlane::Actions::IosUpdateMetadataSourceAction do
  before do
    # This works around the `ensure_git_status_clean` call within the action.
    #
    # We can't easily remove the need to stub the call here without removing the check in the action.
    # In the tests, we move into a temp folder, but then create files in that directory.
    # So, `ensure_git_status_clean` will fail anyway, unless we add more cruft to the tests.
    #
    # See also conversation in
    # https://github.com/wordpress-mobile/release-toolkit/pull/352
    allow(Fastlane::Actions::EnsureGitStatusCleanAction).to receive(:run)
  end

  include_examples 'update_metadata_source_action', whats_new_fails: false
end
