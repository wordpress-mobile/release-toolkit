require 'spec_helper'

describe Fastlane::Actions::IosGeneratePoFileFromMetadataAction do
  it 'create the .po files based on the .txt files in metadata_directory' do
    in_tmp_dir do |dir|
      required_keys = %w[release_notes name subtitle description keywords release_notes_previous].freeze
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
        msgctxt "app_store_release_note_009"
        msgid ""
        "0.9\\n"
        "value release_notes_previous\\n"
        msgstr ""

        # .translators: Keywords used in the App Store search engine to find the app.
        # .Delimit with a comma between each keyword. Limit to 100 characters including spaces and commas.
        msgctxt "app_store_keywords"
        msgid "value keywords"
        msgstr ""

        # .translators: The application name in the Apple App Store. Please keep the brand names ('Jetpack' and WordPress') verbatim. Limit to 30 characters including spaces and punctuation!
        msgctxt "app_store_name"
        msgid "value name"
        msgstr ""

        # .translators: Multi-paragraph text used to display in the Apple App Store.
        msgctxt "app_store_description"
        msgid "value description"
        msgstr ""

        # .translators: Description for the first app store image
        msgctxt "app_store_promo_screenshot_1"
        msgid "What you are reading is coming from another source"
        msgstr ""

        # .translators: Description for the second app store image
        msgctxt "app_store_promo_screenshot_2"
        msgid "What you are reading is coming from another source again"
        msgstr ""

        # .translators: Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!
        msgctxt "app_store_release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        # .translators: Subtitle to be displayed below the application name in the Apple App Store. Limit to 30 characters including spaces and commas!
        msgctxt "app_store_subtitle"
        msgid "value subtitle"
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
      required_keys = %w[release_notes name subtitle description keywords release_notes_previous].freeze
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
        msgctxt "app_store_release_note_009"
        msgid ""
        "0.9\\n"
        "value release_notes_previous\\n"
        msgstr ""

        # .translators: Description for the second app store image
        msgctxt "app_store_promo_screenshot_2"
        msgid "What you are reading is coming from another source again"
        msgstr ""

        # .translators: Subtitle to be displayed below the application name in the Apple App Store. Limit to 30 characters including spaces and commas!
        msgctxt "app_store_subtitle"
        msgid "value subtitle"
        msgstr ""

        # .translators: Keywords used in the App Store search engine to find the app.
        # .Delimit with a comma between each keyword. Limit to 100 characters including spaces and commas.
        msgctxt "app_store_keywords"
        msgid "value keywords"
        msgstr ""

        # .translators: The application name in the Apple App Store. Please keep the brand names ('Jetpack' and WordPress') verbatim. Limit to 30 characters including spaces and punctuation!
        msgctxt "app_store_name"
        msgid "value name"
        msgstr ""

        # .translators: Multi-paragraph text used to display in the Apple App Store.
        msgctxt "app_store_description"
        msgid "value description"
        msgstr ""

        # .translators: Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!
        msgctxt "app_store_release_note_010"
        msgid ""
        "1.0\\n"
        "value release_notes\\n"
        msgstr ""

        # .translators: Description for the first app store image
        msgctxt "app_store_promo_screenshot_1"
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
