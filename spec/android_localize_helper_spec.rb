require 'spec_helper.rb'

describe Fastlane::Helper::Android::LocalizeHelper do
  describe 'get_library_version_from_gradle_config' do
    it 'returns nil when gradle file is not present' do
      allow(File).to receive(:exists?).and_return(false)
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to be_nil
    end

    it 'returns nil when the key is not present' do
      test_file_content = 'my-test-key-foo = \'foo\''
      test_file_content += 'my-test-key-bad = \'bad\''
      test_file_content += 'my-test-key = \'my_test_value\''

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key2')).to be_nil
    end

    it 'returns the key content when the key is present' do
      test_file_content = 'my-test-key-foo = \'foo\''
      test_file_content += 'my-test-key-bad = \'bad\''
      test_file_content += 'my-test-key = \'my_test_value\''

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')

      # Make sure it handles double quotes
      test_file_content = 'my-test-key-foo = \'foo\''
      test_file_content += 'some-other-content = "dummy"'
      test_file_content += 'my-test-key = "my_test_value"'
      
      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')
    end
  end
end
