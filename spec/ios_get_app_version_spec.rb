require 'spec_helper'

describe Fastlane::Actions::IosGetAppVersionAction do
  describe 'getting the public app version from the provided .xcconfig file' do
    it 'parses the xcconfig file format correctly and gets the public version' do
      allow(FastlaneCore::UI).to receive(:confirm).and_return(true)

      xcconfig_mock_content = <<~CONTENT
        // a comment
        VERSION_SHORT = 6
        VERSION_LONG = 6.30.0
      CONTENT

      expect_version(xcconfig_mock_content: xcconfig_mock_content, expected_version: '6.30')
    end

    it 'parses the xcconfig file format correctly and gets the public hotfix version' do
      allow(FastlaneCore::UI).to receive(:confirm).and_return(true)

      xcconfig_mock_content = <<~CONTENT
        VERSION_SHORT = 6
        // a comment
        VERSION_LONG = 6.30.1
      CONTENT

      expect_version(xcconfig_mock_content: xcconfig_mock_content, expected_version: '6.30.1')
    end

    it 'parses the xcconfig with keys without spacing and gets the public version' do
      allow(FastlaneCore::UI).to receive(:confirm).and_return(true)

      xcconfig_mock_content = <<~CONTENT
        // a comment
        VERSION_SHORT=6
        VERSION_LONG=6.30.0
      CONTENT

      expect_version(xcconfig_mock_content: xcconfig_mock_content, expected_version: '6.30')
    end

    it 'parses the xcconfig with keys without spacing and gets the public hotfix version' do
      allow(FastlaneCore::UI).to receive(:confirm).and_return(true)

      xcconfig_mock_content = <<~CONTENT
        VERSION_SHORT=6
        // a comment
        VERSION_LONG=6.30.1
      CONTENT

      expect_version(xcconfig_mock_content: xcconfig_mock_content, expected_version: '6.30.1')
    end

    it 'fails to extract the version from an xcconfig file with an invalid format' do
      allow(FastlaneCore::UI).to receive(:confirm).and_return(true)

      xcconfig_mock_content = <<~CONTENT
        VERSION_SHORT = 6
        VERSION_LONG 6.30.1
      CONTENT

      expect do
        expect_version(xcconfig_mock_content: xcconfig_mock_content, expected_version: 'n/a')
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end

    it 'throws an error when the file is not found' do
      allow(FastlaneCore::UI).to receive(:confirm).and_return(true)

      file_path = 'file/not/found'

      expect do
        run_described_fastlane_action(
          public_version_xcconfig_file: file_path
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end

    it "throws an error when there isn't a version configured in the .xcconfig file" do
      allow(FastlaneCore::UI).to receive(:confirm).and_return(true)

      xcconfig_mock_content = <<~CONTENT
        VERSION_SHORT = 6
        // a comment
      CONTENT

      expect do
        expect_version(xcconfig_mock_content: xcconfig_mock_content, expected_version: 'n/a')
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end

    def expect_version(xcconfig_mock_content:, expected_version:)
      with_tmp_file(named: 'mock_xcconfig.xcconfig', content: xcconfig_mock_content) do |tmp_file_path|
        version_result = run_described_fastlane_action(
          public_version_xcconfig_file: tmp_file_path
        )

        expect(version_result).to eq(expected_version)
      end
    end
  end
end
