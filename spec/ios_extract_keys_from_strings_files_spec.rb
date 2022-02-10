require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::IosExtractKeysFromStringsFilesAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_extract_keys_from_strings_files') }

  it 'extracts the right keys from Localizable.strings to InfoPlist.strings for all locales but the base one' do
    Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
      # Arrange
      lproj_source_dir = File.join(tmp_dir, 'Resources')
      FileUtils.cp_r(File.join(test_data_dir, 'source/'), lproj_source_dir) # slash at end of `source/` makes sure we copy the dir content, not the dir itself

      # Act
      run_described_fastlane_action(
        lprojs_parent_dir: lproj_source_dir,
        source_tablename: 'Localizable',
        target_tablename: 'InfoPlist',
        base_locale: 'en'
      )

      # Assert
      fr_output_file = File.join(lproj_source_dir, 'fr.lproj', 'InfoPlist.strings')
      fr_expected_file = File.join(test_data_dir, 'InfoPlist-expected-fr.strings')
      expect(File).to exist(fr_output_file)
      expect(File.read(fr_output_file)).to eq(File.read(fr_expected_file))

      zh_output_file = File.join(lproj_source_dir, 'zh-Hans.lproj', 'InfoPlist.strings')
      zh_expected_file = File.join(test_data_dir, 'InfoPlist-expected-zh-Hans.strings')
      expect(File).to exist(zh_output_file)
      expect(File.read(zh_output_file)).to eq(File.read(zh_expected_file))
    end
  end
end
