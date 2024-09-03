require 'spec_helper'

describe Fastlane::Helper::Android::VersionHelper do
  before do
    stub_const('BUILD_GRADLE_PATH', './build.gradle')
    stub_const('VERSION_PROPERTIES_PATH', './version.properties')
  end

  describe 'get_release_version' do
    it 'returns version name and code when present' do
      test_file_content = <<~CONTENT
        # Some header

        versionName=17.0
        versionCode=123

        alpha.versionName=alpha-222
        alpha.versionCode=1234
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(test_file_content)
      expect(subject.get_release_version(version_properties_path: VERSION_PROPERTIES_PATH)).to eq('name' => '17.0', 'code' => 123)
    end

    it 'returns alpha version name and code when present' do
      test_file_content = <<~CONTENT
        # Some header

        versionName=17.0
        versionCode=123
        alpha.versionName=alpha-222
        alpha.versionCode=1234
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(test_file_content)
      expect(subject.get_release_version(version_properties_path: VERSION_PROPERTIES_PATH, is_alpha: true)).to eq('name' => 'alpha-222', 'code' => 1234)
    end

    it 'returns nil when alpha version name and code not present' do
      test_file_content = <<~CONTENT
        versionName=17.0
        versionCode=123
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(test_file_content)
      expect(subject.get_release_version(version_properties_path: VERSION_PROPERTIES_PATH, is_alpha: true)).to be_nil
    end
  end

  describe 'get_library_version_from_gradle_config' do
    it 'returns nil when gradle file is not present' do
      allow(File).to receive(:exist?).and_return(false)
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil
    end

    it 'returns nil when the key is not present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key = 'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key-b', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil
      expect(subject.get_library_version_from_gradle_config(import_key: 'test-key', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil
    end

    it 'returns the key content when the key is present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key =  'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')

      # Make sure it handles double quotes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "bad"
        my-test-key = "my_test_value"
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')

      # Make sure it works with prefixes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "extbad"
        ext.my-test-key = 'my_test_value'
        ext..my_test_key_double = 'foo'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')
      expect(subject.get_library_version_from_gradle_config(import_key: 'my_test_key_double', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil

      # Make sure it works with spaces starting the line
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "extbad"
              ext.my-test-key = 'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')
    end
  end
end
