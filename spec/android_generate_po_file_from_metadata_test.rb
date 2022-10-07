require 'spec_helper'

describe Fastlane::Actions::AndroidGeneratePoFileFromMetadataAction do
  it 'create the .po files based on the .txt files in metadata_directory' do
    in_tmp_dir do |dir|
      required_keys = %w[full_description title short_description release_notes release_notes_short release_notes_previous].freeze
      # required_files = required_keys.map { |key| File.join(dir, "#{key}.txt") }

      # For each key create a key.txt file whose content is "value key"
      required_keys.each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end

      output_po_path = File.join(dir, 'PlayStoreStrings.po')

      in_tmp_dir do |another_dir|

        # Create other files in another_dir to test out other_sources API parameter
        another_file = File.join(another_dir, 'promo_screenshot_1.txt')
        another_file_again = File.join(another_dir, 'promo_screenshot_2.txt')
        File.write(another_file, 'What you are reading is coming from another source')
        File.write(another_file_again, 'What you are reading is coming from another source again')

        run_described_fastlane_action(
          metadata_directory: dir,
          release_version: '1.0',
          other_sources: [
            another_dir,
          ]
        )
      end


      expected = <<~PO
        msgctxt "play_store_release_note_009"
        msgid ""
        "0.9\\n"
        "value release_notes_previous\\n"
        msgstr ""

        msgctxt "play_store_release_notes_short"
        msgid "value release_notes_short"
        msgstr ""

        # .translators: Title to be displayed in the Play Store. Limit to 30 characters including spaces and commas!
        msgctxt "play_store_title"
        msgid "value title"
        msgstr ""

        # .translators: Short description of the app to be displayed in the Play Store. Limit to 80 characters including spaces and commas!
        msgctxt "play_store_short_description"
        msgid "value short_description"
        msgstr ""

        # .translators: Description for the first app store image
        msgctxt "play_store_promo_screenshot_1"
        msgid "What you are reading is coming from another source"
        msgstr ""

        # .translators: Description for the second app store image
        msgctxt "play_store_promo_screenshot_2"
        msgid "What you are reading is coming from another source again"
        msgstr ""

        # .translators: Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!
        msgctxt "play_store_release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        # .translators: Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!
        msgctxt "play_store_full_description"
        msgid "value full_description"
        msgstr ""
      PO

      # TODO: remove these line when PR is ready
      # File.write('/Users/juza/Projects/release-toolkit/Test/po', File.read(output_po_path))
      # File.write('/Users/juza/Projects/release-toolkit/Test/expected', expected)
      expect(File.read(output_po_path)).to eq(expected)
    end
  end

  it 'test missing required .txt file' do
    in_tmp_dir do |dir|
      required_keys = %w[full_description title].freeze
      # required_files = required_keys.map { |key| File.join(dir, "#{key}.txt") }

      # For each key create a key.txt file whose content is "value key"
      required_keys.each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end
      expect do
        run_described_fastlane_action(
          metadata_directory: dir,
          release_version: '1.0'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end
  end

  it 'test additional `.txt` files in `metadata_directory`' do
    in_tmp_dir do |dir|
      required_keys = %w[full_description title short_description release_notes release_notes_short release_notes_previous].freeze
      # required_files = required_keys.map { |key| File.join(dir, "#{key}.txt") }

      # For each key create a key.txt file whose content is "value key"
      required_keys.each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end

      output_po_path = File.join(dir, 'PlayStoreStrings.po')


      another_file = File.join(dir, 'promo_screenshot_1.txt')
      another_file_again = File.join(dir, 'promo_screenshot_2.txt')
      File.write(another_file, 'What you are reading is coming from another source')
      File.write(another_file_again, 'What you are reading is coming from another source again')

      run_described_fastlane_action(
        metadata_directory: dir,
        release_version: '1.0',
      )

      expected = <<~PO
        msgctxt "play_store_release_note_009"
        msgid ""
        "0.9\\n"
        "value release_notes_previous\\n"
        msgstr ""

        # .translators: Description for the second app store image
        msgctxt "play_store_promo_screenshot_2"
        msgid "What you are reading is coming from another source again"
        msgstr ""

        # .translators: Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!
        msgctxt "play_store_full_description"
        msgid "value full_description"
        msgstr ""

        msgctxt "play_store_release_notes_short"
        msgid "value release_notes_short"
        msgstr ""

        # .translators: Title to be displayed in the Play Store. Limit to 30 characters including spaces and commas!
        msgctxt "play_store_title"
        msgid "value title"
        msgstr ""

        # .translators: Short description of the app to be displayed in the Play Store. Limit to 80 characters including spaces and commas!
        msgctxt "play_store_short_description"
        msgid "value short_description"
        msgstr ""

        # .translators: Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!
        msgctxt "play_store_release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        # .translators: Description for the first app store image
        msgctxt "play_store_promo_screenshot_1"
        msgid "What you are reading is coming from another source"
        msgstr ""
      PO

      # TODO: remove these line when PR is ready
      File.write('/Users/juza/Projects/release-toolkit/Test/po', File.read(output_po_path))
      File.write('/Users/juza/Projects/release-toolkit/Test/expected', expected)
      expect(File.read(output_po_path)).to eq(expected)
    end
  end
end
