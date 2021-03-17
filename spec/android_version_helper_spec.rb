require 'spec_helper.rb'

describe Fastlane::Helper::Android::VersionHelper do
  describe 'get_library_version_from_gradle_config' do
    it 'returns nil when gradle file is not present' do
      allow(File).to receive(:exists?).and_return(false)
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to be_nil
    end

    it 'returns nil when the key is not present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key = 'my_test_value'
      CONTENT

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key-b')).to be_nil
      expect(subject.get_library_version_from_gradle_config(import_key: 'test-key')).to be_nil
    end

    it 'returns the key content when the key is present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key =  'my_test_value'
      CONTENT

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')

      # Make sure it handles double quotes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "bad"
        my-test-key = "my_test_value"
      CONTENT

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')

      # Make sure it works with prefixes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "extbad"
        ext.my-test-key = 'my_test_value'
        ext..my_test_key_double = 'foo'
      CONTENT

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')
      expect(subject.get_library_version_from_gradle_config(import_key: 'my_test_key_double')).to be_nil
    end
  end
end
