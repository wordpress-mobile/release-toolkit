require 'spec_helper'
require 'shared_examples_for_update_metadata_source_action'

describe Fastlane::Actions::AnUpdateMetadataSourceAction do
  include_examples 'update_metadata_source_action', whats_new_fails: true

  it 'combines the given `release_version` and `release_notes` in a new block, keeps the n-1 ones, and deletes the others' do
    in_tmp_dir do |dir|
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "release_note_0122"
        msgid "previous version notes required to have current one added"
        msgstr ""
        msgctxt "release_note_0121"
        msgid "this older release notes block should be removed"
        msgstr ""
        msgctxt "release_note_0120"
        msgid "this older release notes block should be removed"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      release_notes_path = File.join(dir, 'release_notes.txt')
      File.write(release_notes_path, "- release notes\n- more release notes")

      run_described_fastlane_action(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          release_note: release_notes_path
        }
      )

      expected = <<~'PO'
        msgctxt "release_note_0123"
        msgid ""
        "1.23:\n"
        "- release notes\n"
        "- more release notes\n"
        msgstr ""

        msgctxt "release_note_0122"
        msgid "previous version notes required to have current one added"
        msgstr ""
      PO
      expect(File.read(output_path).inspect).to eq(expected.inspect)
    end
  end
end
