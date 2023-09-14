require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/helper/ios/ios_version_helper'

describe Fastlane::Helper::Ios::VersionHelper do
  describe '.write_to_xcconfig_file' do
    context 'when the .xcconfig file exists' do
      it 'writes the key-value pair to the .xcconfig file' do
        file_path = 'spec/test-data/test.xcconfig'
        key = 'BUILD_NUMBER'
        value = '1234'
        described_class.write_to_xcconfig_file(key, value, file_path)
        file_content = File.read(file_path)

        expect(file_content).to include("#{key} = #{value}")
      end
    end

    context 'when the .xcconfig file does not exist' do
      file_path = 'fake_path/test.xcconfig'
      key = 'BUILD_NUMBER'
      value = '1234'

      it 'raises an error' do
        expect { described_class.write_to_xcconfig_file(key, value, file_path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /\.xcconfig file .* not found/)
      end
    end
  end
end
