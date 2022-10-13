require 'spec_helper'

required_keys = %w[full_description title short_description release_notes].freeze

describe Fastlane::Actions::AndroidGeneratePoFileFromMetadataAction do
  it 'create the .po file based on the `.txt` files in `metadata_directory` along with `other_sources` param' do
    in_tmp_dir do |dir|
      # For each key create a key.txt file whose content is "value key"
      required_keys.each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end

      # Now create release_notes_short.txt and release_notes_previous.txt
      %w[release_notes_short release_notes_previous].each do |key|
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
        # Translation of Release Notes & Apple Store Description in English (US)
        # This file is distributed under the same license as the Release Notes & Apple Store Description package.
        msgid ""
        msgstr ""
        "MIME-Version: 1.0\\n"
        "Content-Type: text/plain; charset=UTF-8\\n"
        "Content-Transfer-Encoding: 8bit\\n"
        "Plural-Forms: nplurals=2; plural=n != 1;\\n"
        "Project-Id-Version: Release Notes & Apple Store Description\\n"
        "POT-Creation-Date:\\n"
        "Last-Translator:\\n"
        "Language-Team:\\n"
        "Language-Team:\\n"

        # .translators: Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!
        msgctxt "play_store_full_description"
        msgid "value full_description"
        msgstr ""

        # .translators: Description for the first app store image
        msgctxt "play_store_promo_screenshot_1"
        msgid "What you are reading is coming from another source"
        msgstr ""

        # .translators: Description for the second app store image
        msgctxt "play_store_promo_screenshot_2"
        msgid "What you are reading is coming from another source again"
        msgstr ""

        msgctxt "play_store_release_note_009"
        msgid ""
        "0.9\\n"
        "value release_notes_previous\\n"
        msgstr ""

        # .translators: Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!
        msgctxt "play_store_release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        # .translators: Shorter Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!
        msgctxt "play_store_release_note_short_010"
        msgid ""
        "1.0\\n"
        "value release_notes_short\\n"
        msgstr ""

        # .translators: Short description of the app to be displayed in the Play Store. Limit to 80 characters including spaces and commas!
        msgctxt "play_store_short_description"
        msgid "value short_description"
        msgstr ""

        # .translators: Title to be displayed in the Play Store. Limit to 30 characters including spaces and commas!
        msgctxt "play_store_title"
        msgid "value title"
        msgstr ""
      PO
      expect(File.read(output_po_path)).to eq(expected)
    end
  end

  it 'test that a missing required .txt file raises a proper error' do
    in_tmp_dir do |dir|
      # For each key create a key.txt file whose content is "value key"
      required_keys[1..].each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end
      expect do
        run_described_fastlane_action(
          metadata_directory: dir,
          release_version: '1.0'
        )
      end.to raise_error 'full_description.txt file(s) is/are required and are missing from `metadata_directory`'
    end
  end

  it 'test that two missing required .txt file raise a proper error' do
    in_tmp_dir do |dir|
      # For each key create a key.txt file whose content is "value key"
      required_keys[2..].each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end
      expect do
        run_described_fastlane_action(
          metadata_directory: dir,
          release_version: '1.0'
        )
      end.to raise_error 'full_description.txt, title.txt file(s) is/are required and are missing from `metadata_directory`'
    end
  end

  it 'test additional loose `.txt` files in `metadata_directory`' do
    in_tmp_dir do |dir|
      # For each key create a key.txt file whose content is "value key"
      required_keys.each do |key|
        write_to = File.join(dir, "#{key}.txt")
        File.write(write_to, "value #{key}")
      end

      # Now create release_notes_short.txt and release_notes_previous.txt
      %w[release_notes_short release_notes_previous].each do |key|
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
        release_version: '1.0'
      )

      expected = <<~PO
        # Translation of Release Notes & Apple Store Description in English (US)
        # This file is distributed under the same license as the Release Notes & Apple Store Description package.
        msgid ""
        msgstr ""
        "MIME-Version: 1.0\\n"
        "Content-Type: text/plain; charset=UTF-8\\n"
        "Content-Transfer-Encoding: 8bit\\n"
        "Plural-Forms: nplurals=2; plural=n != 1;\\n"
        "Project-Id-Version: Release Notes & Apple Store Description\\n"
        "POT-Creation-Date:\\n"
        "Last-Translator:\\n"
        "Language-Team:\\n"
        "Language-Team:\\n"

        # .translators: Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!
        msgctxt "play_store_full_description"
        msgid "value full_description"
        msgstr ""

        # .translators: Description for the first app store image
        msgctxt "play_store_promo_screenshot_1"
        msgid "What you are reading is coming from another source"
        msgstr ""

        # .translators: Description for the second app store image
        msgctxt "play_store_promo_screenshot_2"
        msgid "What you are reading is coming from another source again"
        msgstr ""

        msgctxt "play_store_release_note_009"
        msgid ""
        "0.9\\n"
        "value release_notes_previous\\n"
        msgstr ""

        # .translators: Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!
        msgctxt "play_store_release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        # .translators: Shorter Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!
        msgctxt "play_store_release_note_short_010"
        msgid ""
        "1.0\\n"
        "value release_notes_short\\n"
        msgstr ""

        # .translators: Short description of the app to be displayed in the Play Store. Limit to 80 characters including spaces and commas!
        msgctxt "play_store_short_description"
        msgid "value short_description"
        msgstr ""

        # .translators: Title to be displayed in the Play Store. Limit to 30 characters including spaces and commas!
        msgctxt "play_store_title"
        msgid "value title"
        msgstr ""
      PO

      expect(File.read(output_po_path)).to eq(expected)
    end
  end
end
