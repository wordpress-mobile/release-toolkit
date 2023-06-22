require 'spec_helper'

describe Fastlane::Actions::VersionAction do
  describe 'getting the build number from the provided .xcconfig file' do
    context 'with an iOS app' do
      it 'parses an xcconfig file with keys without spaces and returns the correct build number' do
        mock_version_content = <<~CONTENT
          // a comment
          VERSION_SHORT=6
          VERSION_LONG=6.30.0
          BUILD_NUMBER=1940
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '1940',
          app_platform: ':ios',
          version_type: 'build_number'
        )
      end

      it 'parses an xcconfig file with keys with spaces and returns the correct build number' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          VERSION_LONG = 6.30.1
          BUILD_NUMBER = 1940
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '1940',
          app_platform: ':ios',
          version_type: 'build_number'
        )
      end

      it 'parses an xcconfig file with an invalid format and returns a nil build number' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          VERSION_LONG = 6.30.1
          BUILD_NUMBER 1940
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: nil,
          app_platform: ':ios',
          version_type: 'build_number'
        )
      end

      it 'parses an xcconfig file with no build number and returns a nil build number' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6twi
          // a comment
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: nil,
          app_platform: ':ios',
          version_type: 'build_number'
        )
      end

      it 'throws an error when the xcconfig file does not exist' do
        expect do
          run_described_fastlane_action(
            version_file_path: 'file/not/found',
            app_platform: ':ios',
            version_type: 'build_number'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end
    end

    context 'with a Mac app' do
      it 'parses an xcconfig file with keys without spaces and returns the correct build number' do
        mock_version_content = <<~CONTENT
          // a comment
          VERSION_SHORT=6
          VERSION_LONG=6.30.0
          BUILD_NUMBER=1940
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '1940',
          app_platform: ':mac',
          version_type: 'build_number'
        )
      end

      it 'parses an xcconfig file with keys with spaces and returns the correct build number' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          VERSION_LONG = 6.30.1
          BUILD_NUMBER = 1940
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '1940',
          app_platform: ':mac',
          version_type: 'build_number'
        )
      end

      it 'parses an xcconfig file with an invalid format and returns a nil build number' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          VERSION_LONG = 6.30.1
          BUILD_NUMBER 1940
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: nil,
          app_platform: ':mac',
          version_type: 'build_number'
        )
      end

      it 'parses an xcconfig file with no build number and returns a nil build number' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6twi
          // a comment
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: nil,
          app_platform: ':mac',
          version_type: 'build_number'
        )
      end

      it 'throws an error when the xcconfig file does not exist' do
        expect do
          run_described_fastlane_action(
            version_file_path: 'file/not/found',
            app_platform: ':mac',
            version_type: 'build_number'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end
    end
  end

  describe 'getting the public version number from the provided .xcconfig file' do
    context 'with an iOS app' do
      it 'parses an xcconfig file with keys without spaces and returns the correct public version' do
        mock_version_content = <<~CONTENT
          // a comment
          VERSION_SHORT=6
          VERSION_LONG=6.30.0
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30',
          app_platform: ':ios',
          version_type: 'public'
        )
      end

      it 'parses an xcconfig file with keys without spaces and returns the correct public hotfix version' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT=6
          // a comment
          VERSION_LONG=6.30.1
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30.1',
          app_platform: ':ios',
          version_type: 'public'
        )
      end

      it 'parses an xcconfig file with keys with spaces and returns the correct public version' do
        mock_version_content = <<~CONTENT
          // a comment
          VERSION_SHORT = 6
          VERSION_LONG = 6.30.0
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30',
          app_platform: ':ios',
          version_type: 'public'
        )
      end

      it 'parses an xcconfig file with keys with spaces and returns the correct public hotfix version' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          // a comment
          VERSION_LONG = 6.30.1
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30.1',
          app_platform: ':ios',
          version_type: 'public'
        )
      end

      it "throws an error when there isn't a version configured in the .xcconfig file" do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          // a comment
        CONTENT

        expect do
          expect_version(
            mock_version_content: mock_version_content,
            expected_version: 'n/a',
            app_platform: ':ios',
            version_type: 'public'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'fails to extract the version from an xcconfig file with an invalid format' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          VERSION_LONG 6.30.1
        CONTENT

        expect do
          expect_version(
            mock_version_content: mock_version_content,
            expected_version: 'n/a',
            app_platform: ':ios',
            version_type: 'public'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'throws an error when the xcconfig file does not exist' do
        expect do
          run_described_fastlane_action(
            version_file_path: 'file/not/found',
            app_platform: ':ios',
            version_type: 'public'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end
    end

    context 'with a Mac app' do
      it 'parses an xcconfig file with keys without spaces and returns the correct public version' do
        mock_version_content = <<~CONTENT
          // a comment
          VERSION_SHORT=6
          VERSION_LONG=6.30.0
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30',
          app_platform: ':mac',
          version_type: 'public'
        )
      end

      it 'parses an xcconfig file with keys without spaces and returns the correct public hotfix version' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT=6
          // a comment
          VERSION_LONG=6.30.1
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30.1',
          app_platform: ':mac',
          version_type: 'public'
        )
      end

      it 'parses an xcconfig file with keys with spaces and returns the correct public version' do
        mock_version_content = <<~CONTENT
          // a comment
          VERSION_SHORT = 6
          VERSION_LONG = 6.30.0
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30',
          app_platform: ':mac',
          version_type: 'public'
        )
      end

      it 'parses an xcconfig file with keys with spaces and returns the correct public hotfix version' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          // a comment
          VERSION_LONG = 6.30.1
        CONTENT

        expect_version(
          mock_version_content: mock_version_content,
          expected_version: '6.30.1',
          app_platform: ':mac',
          version_type: 'public'
        )
      end

      it "throws an error when there isn't a version configured in the .xcconfig file" do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          // a comment
        CONTENT

        expect do
          expect_version(
            mock_version_content: mock_version_content,
            expected_version: 'n/a',
            app_platform: ':mac',
            version_type: 'public'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'fails to extract the version from an xcconfig file with an invalid format' do
        mock_version_content = <<~CONTENT
          VERSION_SHORT = 6
          VERSION_LONG 6.30.1
        CONTENT

        expect do
          expect_version(
            mock_version_content: mock_version_content,
            expected_version: 'n/a',
            app_platform: ':mac',
            version_type: 'public'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'throws an error when the xcconfig file does not exist' do
        expect do
          run_described_fastlane_action(
            version_file_path: 'file/not/found',
            app_platform: ':mac',
            version_type: 'public'
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end
    end
  end

  describe 'when app_platform is :android' do
    context 'when getting the alpha version from ./version.properties' do
      it 'returns alpha version name and code when present' do
        mock_version_content = <<~CONTENT
          # Some header

          versionName=17.0
          versionCode=123
          alpha.versionName=alpha-222
          alpha.versionCode=1234
        CONTENT

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(mock_version_content)

        version_result = run_described_fastlane_action(
          app_platform: ':android',
          version_type: 'alpha',
          version_file_path: './version.properties'
        )

        expect(version_result).to eq({ 'name' => 'alpha-222', 'code' => 1234 })
      end

      it 'returns nil when alpha version name and code are not present' do
        mock_version_content = <<~CONTENT
          versionName=17.0
          versionCode=123
        CONTENT

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(mock_version_content)

        version_result = run_described_fastlane_action(
          app_platform: ':android',
          version_type: 'alpha',
          version_file_path: './version.properties'
        )

        expect(version_result).to be_nil
      end
    end
  end

  describe 'Android - returns the release version' do
    context 'when getting the release version from ./version.properties' do
      it 'returns release version name and code when present in ./version.properties' do
        mock_version_content = <<~CONTENT
          # Some header

          versionName=17.0
          versionCode=123

          alpha.versionName=alpha-222
          alpha.versionCode=1234
        CONTENT

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(mock_version_content)

        version_result = run_described_fastlane_action(
          app_platform: ':android',
          version_type: 'release',
          version_file_path: './version.properties'
        )

        expect(version_result).to eq('name' => '17.0', 'code' => 123)
      end

      it 'returns nil when release version name and code are not present' do
        mock_version_content = <<~CONTENT
          # This is a header
          # But no versions!
        CONTENT

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(mock_version_content)

        version_result = run_described_fastlane_action(
          app_platform: ':android',
          version_type: 'release',
          version_file_path: './version.properties'
        )

        expect(version_result).to be_nil
      end
    end
  end

  describe 'Android - returns the public version' do
    context 'when getting the public version from ./version.properties' do
      it 'returns public version when present in ./version.properties' do
        mock_version_content = <<~CONTENT
          # Some header

          versionName=17.0
          versionCode=123

          alpha.versionName=alpha-222
          alpha.versionCode=1234
        CONTENT

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(mock_version_content)

        version_result = run_described_fastlane_action(
          app_platform: ':android',
          version_type: 'public',
          version_file_path: './version.properties'
        )

        expect(version_result).to eq('17.0')
      end

      it 'returns public hotfix version when present in ./version.properties' do
        mock_version_content = <<~CONTENT
          # Some header

          versionName=17.0.2
          versionCode=123

          alpha.versionName=alpha-222
          alpha.versionCode=1234
        CONTENT

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(mock_version_content)

        version_result = run_described_fastlane_action(
          app_platform: ':android',
          version_type: 'public',
          version_file_path: './version.properties'
        )

        expect(version_result).to eq('17.0.2')
      end

      it 'returns nil when public version name is not present' do
        mock_version_content = <<~CONTENT
          # This is a header
          # But no versions!
        CONTENT

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(mock_version_content)

        version_result = run_described_fastlane_action(
          app_platform: ':android',
          version_type: 'public',
          version_file_path: './version.properties'
        )

        expect(version_result).to be_nil
      end
    end
  end

  def expect_version(mock_version_content:, expected_version:, app_platform:, version_type:)
    with_tmp_file(named: 'mock_xcconfig.tmp', content: mock_version_content) do |tmp_file_path|
      version_result = run_described_fastlane_action(
        app_platform: app_platform,
        version_type: version_type,
        version_file_path: tmp_file_path
      )

      expect(version_result).to eq(expected_version)
    end
  end
end
