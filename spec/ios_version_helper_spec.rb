require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/helper/ios/ios_version_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/build_code'

describe Fastlane::Helper::Ios::VersionHelper do
  describe 'write the provided key and value to an xcconfig file' do
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

  describe 'read the build code from the provided .xcconfig file' do
    context 'when the .xcconfig file exists' do
      it 'reads the build code from the .xcconfig file' do
        file_path = 'spec/test-data/test.xcconfig'
        build_code = described_class.read_build_code_from_xcconfig_file(file_path)

        expect(build_code.to_s).to eq('1234')
      end
    end

    context 'when the .xcconfig file does not exist' do
      it 'raises an error' do
        file_path = 'fake_path/test.xcconfig'

        expect { described_class.read_build_code_from_xcconfig_file(file_path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /\.xcconfig file .* not found/)
      end
    end
  end

  describe 'read the version number from the provided .xcconfig file' do
    context 'when the .xcconfig file exists' do
      it 'reads the version number from the .xcconfig file' do
        file_path = 'spec/test-data/test.xcconfig'
        version = described_class.read_version_number_from_xcconfig_file(file_path)

        expect(version.to_s).to eq('2023.19.0.0')
      end
    end

    context 'when the .xcconfig file does not exist' do
      it 'raises an error' do
        file_path = 'fake_path/test.xcconfig'

        expect { described_class.read_version_number_from_xcconfig_file(file_path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /\.xcconfig file .* not found/)
      end
    end
  end
end
