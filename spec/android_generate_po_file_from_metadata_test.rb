require 'spec_helper'

describe Fastlane::Actions::AnGeneratePoFileFromMetadataAction do
  it 'create the .po files based on the .txt files in metadata_directory' do
    in_tmp_dir do |dir|
      required_keys = %w[description keywords name release_notes].freeze
      # required_files = required_keys.map { |key| File.join(dir, "#{key}.txt") }

      # For each key create a key.txt file whose content is "value key"
      required_keys.each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end

      output_po_path = File.join(dir, 'PlayStoreStrings.po')

      run_described_fastlane_action(
        metadata_directory: dir,
        release_version: '1.0'
      )

      expected = <<~PO
        msgctxt "play_store_keywords"
        msgid "value keywords"
        msgstr ""

        msgctxt "release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        msgctxt "play_store_name"
        msgid "value name"
        msgstr ""

        msgctxt "play_store_description"
        msgid "value description"
        msgstr ""
      PO

      expect(File.read(output_po_path)).to eq(expected)
    end
  end
end
