require 'spec_helper'

describe Fastlane::Actions::IosGetBuildNumberAction do
  describe 'getting the build number from the provided .xcconfig file' do
    it 'parses an xcconfig file with keys without spacing and returns the correct build number' do
      xcconfig_mock_content = <<~CONTENT
        // a comment
        VERSION_SHORT=6
        VERSION_LONG=6.30.0
        BUILD_NUMBER=1940
      CONTENT

      expect_build_number(xcconfig_mock_content: xcconfig_mock_content, expected_build_number: '1940')
    end

    it 'parses an xcconfig file with keys with spaces and returns the correct build number' do
      xcconfig_mock_content = <<~CONTENT
        VERSION_SHORT = 6w
        VERSION_LONG = 6.30.1
        BUILD_NUMBER = 1940
      CONTENT

      expect_build_number(xcconfig_mock_content: xcconfig_mock_content, expected_build_number: '1940')
    end

    it 'parses an xcconfig file with an invalid format and returns a nil build number' do
      xcconfig_mock_content = <<~CONTENT
        VERSION_SHORT = 6
        VERSION_LONG = 6.30.1
        BUILD_NUMBER 1940
      CONTENT

      expect_build_number(xcconfig_mock_content: xcconfig_mock_content, expected_build_number: nil)
    end

    it 'parses an xcconfig file with no build number and returns a nil build number' do
      xcconfig_mock_content = <<~CONTENT
        VERSION_SHORT = 6
        // a comment
      CONTENT

      expect_build_number(xcconfig_mock_content: xcconfig_mock_content, expected_build_number: nil)
    end

    it 'throws an error when the xcconfig file does not exist' do
      expect do
        run_described_fastlane_action(
          xcconfig_file_path: 'file/not/found'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end

    def expect_build_number(xcconfig_mock_content:, expected_build_number:)
      with_tmp_file(named: 'mock_xcconfig.xcconfig', content: xcconfig_mock_content) do |tmp_file_path|
        build_number_result = run_described_fastlane_action(
          xcconfig_file_path: tmp_file_path
        )

        expect(build_number_result).to eq(expected_build_number)
      end
    end
  end
end
