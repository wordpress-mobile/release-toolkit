require 'spec_helper.rb'

describe Fastlane::Helper::Android::LocalizeHelper do
  describe 'get_library_version_from_gradle_config' do
    it 'returns nil when gradle file is not present' do
      allow(File).to receive(:exists?).and_return(false)
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to be_nil
    end

    it 'returns nil when the key is not present' do
      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new('my-test-key = \'my_test_value\''))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key2')).to be_nil
    end

    it 'returns the key content when the key is present' do
      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new('my-test-key = \'my_test_value\''))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')
    end
  end
end
