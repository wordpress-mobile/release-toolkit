require 'spec_helper'
require 'shared_examples_for_update_metadata_source_action'

describe Fastlane::Actions::AnUpdateMetadataSourceAction do
  include_examples 'update_metadata_source_action', whats_new_fails: true
end
