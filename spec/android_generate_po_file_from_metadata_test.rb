require 'spec_helper'
require 'shared_examples_for_generate_po_file_from_metadata_action'

describe Fastlane::Actions::AnGeneratePoFileFromMetadataAction do
  include_examples 'generate_po_file_from_metadata_action', whats_new_fails: true
end
