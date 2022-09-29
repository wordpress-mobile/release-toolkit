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
end
