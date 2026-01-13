# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples_for_update_metadata_source_action'

describe Fastlane::Actions::AnUpdateMetadataSourceAction do
  include_examples 'update_metadata_source_action'

  it 'generates a versioned release_note entry from the given source file' do
    in_tmp_dir do |dir|
      output_path = File.join(dir, 'output.po')

      release_notes_path = File.join(dir, 'release_notes.txt')
      File.write(release_notes_path, "- release notes\n- more release notes")

      run_described_fastlane_action(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          release_note: release_notes_path
        }
      )

      result = File.read(output_path)
      expect(result).to include('msgctxt "release_note_0123"')
      expect(result).to include('"1.23:\n"')
      expect(result).to include('"- release notes\n"')
      expect(result).to include('"- more release notes\n"')
    end
  end
end
