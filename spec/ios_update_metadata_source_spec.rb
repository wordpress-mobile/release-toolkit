require 'spec_helper'
require 'shared_examples_for_update_metadata_source_action'

describe Fastlane::Actions::IosUpdateMetadataSourceAction do
  before do
    # This works around the `ensure_git_status_clean` call within the action.
    # It would be quite cumbersome to iterate on the code if we had to commit
    # every change _before_ running the tests...
    allow(Fastlane::Actions::EnsureGitStatusCleanAction).to receive(:run)
  end

  include_examples 'update_metadata_source_action', whats_new_fails: false
end
