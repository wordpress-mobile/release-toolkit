require 'spec_helper'

describe Fastlane::Actions::GpUpdateMetadataSourceAction do
  it 'updates any block in a given .po file with the values from the given sources' do
    Dir.mktmpdir do |dir|
      # 1: Create a dummy .po file to use as input.
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "v1.0-whats-new"
        msgid "this value should change"
        msgstr ""
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
      whats_new_path = File.join(dir, 'whats_new.txt')
      File.write(whats_new_path, "- something new\n- something else new")
      file_1_path = File.join(dir, '1.txt')
      File.write(file_1_path, 'value 1')
      file_2_path = File.join(dir, '2.txt')
      File.write(file_2_path, 'value 2')

      described_class.run(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          release_note: release_notes_path,
          whats_new: whats_new_path,
          key1: file_1_path,
          key2: file_2_path
        }
      )

      # 3: Assert given .po has been updated as expected
      #
      # Notice:
      #
      # - The new line after each block is added by the conversion
      # - That there's no new line between release_note_0122 and key1, because
      #   the notes are copied as they are with no extra manipulation
      expected = <<~PO
        msgctxt "v1.23-whats-new"
        msgid ""
        "- something new\\n"
        "- something else new\\n"
        msgstr ""

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

  it 'adds entries passed as input even if not part of the original `.po` file' do
    pending 'this currently fails and will be addressed as part of the upcoming refactor/rewrite of the functionality'
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "key1"
        msgid "this value should change"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      # 2: Create source files with value to insert in the .po
      file_1_path = File.join(dir, '1.txt')
      File.write(file_1_path, 'value 1')
      file_2_path = File.join(dir, '2.txt')
      File.write(file_2_path, 'value 2')

      described_class.run(
        po_file_path: output_path,
        source_files: {
          key1: file_1_path,
          key2: file_2_path
        }
      )

      expected = <<~PO
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
end
