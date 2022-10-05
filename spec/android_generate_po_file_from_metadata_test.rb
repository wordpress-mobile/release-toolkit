require 'spec_helper'
require 'json'

describe Fastlane::Actions::AndroidGeneratePoFileFromMetadataAction do
  it 'create the .po files based on the .txt files in metadata_directory' do
    in_tmp_dir do |dir|
      required_keys = %w[description keywords name release_notes release_notes_previous].freeze

      # For each key create a key.txt file whose content is "value key"
      # Also fill up the key_to_comment_hash
      key_to_comment_hash = {}
      required_keys.each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
        key_to_comment_hash[key] = "Comment for #{key}"
      end

      comments_path = File.join(dir, 'comments.json')
      File.write(comments_path, JSON.pretty_generate(key_to_comment_hash))

      output_po_path = File.join(dir, 'PlayStoreStrings.po')

      run_described_fastlane_action(
        metadata_directory: dir,
        release_version: '1.0'
      )

      expected = <<~PO
        # .translators: Comment for keywords
        msgctxt "play_store_keywords"
        msgid "value keywords"
        msgstr ""

        # .translators: Comment for name
        msgctxt "play_store_name"
        msgid "value name"
        msgstr ""

        # .translators: Comment for description
        msgctxt "play_store_description"
        msgid "value description"
        msgstr ""

        msgctxt "play_store_release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        msgctxt "play_store_release_note_009"
        msgid ""
        "0.9\\n"
        "value release_notes_previous\\n"
        msgstr ""
      PO

      expect(File.read(output_po_path)).to eq(expected)
    end
  end
end

