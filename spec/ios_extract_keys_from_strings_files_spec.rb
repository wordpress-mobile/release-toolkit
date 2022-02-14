require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::IosExtractKeysFromStringsFilesAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_extract_keys_from_strings_files') }

  describe 'extract the right keys from `Localizable.strings` to all locales' do
    def assert_output_files_match(expectations_map)
      expectations_map.each do |output_file, expected_file|
        expect(File).to exist(output_file), "expect `#{output_file}` to exist"
        expect(File.read(output_file)).to eq(File.read(File.join(test_data_dir, expected_file))), "expect content of `#{output_file}` to match `#{expected_file}`"
      end
    end

    it 'can extract keys to a single `InfoPlist.strings` target table' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        lproj_source_dir = File.join(tmp_dir, 'LocalizationFiles')
        FileUtils.cp_r(File.join(test_data_dir, 'Resources', '.'), lproj_source_dir)

        # Act
        run_described_fastlane_action(
          source_parent_dir: lproj_source_dir,
          target_original_files: File.join(lproj_source_dir, 'en.lproj', 'InfoPlist.strings')
        )

        # Assert
        assert_output_files_match(
          File.join(lproj_source_dir, 'fr.lproj', 'InfoPlist.strings') => 'InfoPlist-expected-fr.strings',
          File.join(lproj_source_dir, 'zh-Hans.lproj', 'InfoPlist.strings') => 'InfoPlist-expected-zh-Hans.strings'
        )
      end
    end

    it 'can extract keys to multiple `.strings` files' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        resources_dir = File.join(tmp_dir, 'Resources')
        siri_intent_dir = File.join(tmp_dir, 'SiriIntentTarget')
        FileUtils.cp_r(File.join(test_data_dir, 'Resources', '.'), resources_dir)
        FileUtils.cp_r(File.join(test_data_dir, 'SiriIntentTarget', '.'), siri_intent_dir)

        # Act
        run_described_fastlane_action(
          source_parent_dir: resources_dir,
          target_original_files: [
            File.join(resources_dir, 'en.lproj', 'InfoPlist.strings'),
            File.join(siri_intent_dir, 'en.lproj', 'Sites.strings'),
          ]
        )

        # Assert
        assert_output_files_match(
          File.join(resources_dir, 'fr.lproj', 'InfoPlist.strings') => 'InfoPlist-expected-fr.strings',
          File.join(siri_intent_dir, 'fr.lproj', 'Sites.strings') => 'Sites-expected-fr.strings',
          File.join(resources_dir, 'zh-Hans.lproj', 'InfoPlist.strings') => 'InfoPlist-expected-zh-Hans.strings',
          File.join(siri_intent_dir, 'zh-Hans.lproj', 'Sites.strings') => 'Sites-expected-zh-Hans.strings'
        )
      end
    end

    it 'supports using an input file other than `Localizable.strings`' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        lproj_source_dir = File.join(tmp_dir, 'NonStandardFiles')
        FileUtils.cp_r(File.join(test_data_dir, 'Resources', '.'), lproj_source_dir)
        Dir.glob('**/Localizable.strings', base: lproj_source_dir).each do |file|
          src_file = File.join(lproj_source_dir, file)
          FileUtils.mv(src_file, File.join(File.dirname(src_file), 'GlotPressTranslations.strings'))
        end

        # Act
        run_described_fastlane_action(
          source_parent_dir: lproj_source_dir,
          source_tablename: 'GlotPressTranslations',
          target_original_files: File.join(lproj_source_dir, 'en.lproj', 'InfoPlist.strings')
        )

        # Assert
        assert_output_files_match(
          File.join(lproj_source_dir, 'fr.lproj', 'InfoPlist.strings') => 'InfoPlist-expected-fr.strings',
          File.join(lproj_source_dir, 'zh-Hans.lproj', 'InfoPlist.strings') => 'InfoPlist-expected-zh-Hans.strings'
        )
      end
    end

    it 'does not overwrite the original files' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        lproj_source_dir = File.join(tmp_dir, 'Resources')
        FileUtils.cp_r(File.join(test_data_dir, 'Resources', '.'), lproj_source_dir)

        # Act
        run_described_fastlane_action(
          source_parent_dir: lproj_source_dir,
          target_original_files: File.join(lproj_source_dir, 'en.lproj', 'InfoPlist.strings')
        )

        # Assert
        assert_output_files_match(
          File.join(lproj_source_dir, 'en.lproj', 'InfoPlist.strings') => File.join('Resources', 'en.lproj', 'InfoPlist.strings')
        )
      end
    end
  end

  describe 'input parameters validation' do
    it 'errors if the source dir does not exist'
    it 'errors if one of the target original files does not exist'
  end

  describe 'error handling during processing' do
    it 'errors it if fails to read the keys to extract'
    it 'errors it if fails to write one of the target files'
  end
end
