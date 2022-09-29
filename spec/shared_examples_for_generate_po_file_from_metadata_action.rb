require 'spec_helper'

RSpec.shared_examples 'generate_po_file_from_metadata_action' do |options|
  it 'create the .po files based on the .txt files in metadata_directory' do
    in_tmp_dir do |dir|
      output_path = File.join(dir, 'PlayStoreStrings.po')


      file_1_path = File.join(dir, 'file_1.txt')
      File.write(file_1_path, 'value 1')
      file_2_path = File.join(dir, 'file_2.txt')
      File.write(file_2_path, 'value 2')

      run_described_fastlane_action(
        metadata_directory: dir,
        release_version: '1.0'
      )

      expected = <<~PO
        msgctxt "play_store_file_1"
        msgid "value 1"
        msgstr ""

        msgctxt "play_store_file_2"
        msgid "value 2"
        msgstr ""
      PO
      expect(File.read(output_path)).to eq(expected)
    end
  end

  it 'testing release_notes.txt in metadata_directory' do |options|
    in_tmp_dir do |dir|
      output_po_path = File.join(dir, 'PlayStoreStrings.po')
      release_notes_path = File.join(dir, 'release_notes.txt')
      release_note_txt = <<~TEXT
        This is the 1st line of the release notes.
        This is the 2nd line of the release notes.
        This is the 3rd line of the release notes.
      TEXT

      File.write(release_notes_path, release_note_txt)

      run_described_fastlane_action(
        metadata_directory: dir,
        release_version: '1.0'
      )

      po = File.read(output_po_path)
      expected = <<~PO
        msgctxt "release_note_010"
        msgid ""
        "1.0\\n"
        "This is the 1st line of the release notes.\\n"
        "This is the 2nd line of the release notes.\\n"
        "This is the 3rd line of the release notes.\\n"
        "\\n"
        msgstr ""
      PO

      expect(File.read(output_po_path)).to eq(expected)

    end
  end

end
