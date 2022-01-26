require 'spec_helper'

describe Fastlane::Actions::AnUpdateMetadataSourceAction do
  it 'updates any block in a given .po file with the values from the given sources' do
    Dir.mktmpdir do |dir|
      # 1: Create a dummy .po file to use as input.
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "release_note_0122"
        msgid "previous version notes required to have current one added"
        msgstr ""
        msgctxt "release_note_0121"
        msgid "this older release notes block should be removed"
        msgstr ""
        msgctxt "key1"
        msgid "this value should change"
        msgstr ""
        msgctxt "key2"
        msgid "this value should change"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      # 2: Create source files with value to insert in the .po
      release_notes_path = File.join(dir, 'release_notes.txt')
      File.write(release_notes_path, "- release notes\n- more release notes")
      file_1_path = File.join(dir, '1.txt')
      File.write(file_1_path, 'value 1')
      file_2_path = File.join(dir, '2.txt')
      File.write(file_2_path, 'value 2')
      file_3_path = File.join(dir, '3.txt')
      File.write(file_3_path, 'value 3')

      described_class.run(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          release_note: release_notes_path,
          key1: file_1_path,
          key2: file_2_path,
          key3: file_3_path # This is not in the input .po and won't be added
        }
      )

      # 3: Assert given .po has been updated as expected
      #
      # Notice:
      #
      # - The new line after each block is added by the conversion
      # - That there's no new line between release_note_0122 and key1, because
      #   the notes are copied as they are with no extra manipulation
      # - The key3 source is not part of the output because was not in the
      #   original .po input
      expected = <<~PO
        msgctxt "release_note_0123"
        msgid ""
        "1.23:\\n"
        "- release notes\\n"
        "- more release notes\\n"
        msgstr ""

        msgctxt "release_note_0122"
        msgid "previous version notes required to have current one added"
        msgstr ""
        msgctxt "key1"
        msgid "value 1"
        msgstr ""

        msgctxt "key2"
        msgid "value 2"
        msgstr ""

      PO
      expect(File.read(output_path)).to eq(expected)
    end
  end

  it 'does not ignore the `whats_new` parameter' do
    pending 'this currently fails; in the long run, we might consolidate whats_new with release_notes'

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "v1.0-whats-new"
        msgid "this will not change"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      whats_new_path = File.join(dir, 'whats_new.txt')
      File.write(whats_new_path, "- something new\n- something else new")

      described_class.run(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          whats_new: whats_new_path
        }
      )

      expected = <<~PO
        msgctxt "v1.23-whats-new"
        msgid ""
        "- something new\\n"
        "- something else new\\n"
        msgstr ""

      PO
      expect(File.read(output_path)).to eq(expected)
    end
  end
end
