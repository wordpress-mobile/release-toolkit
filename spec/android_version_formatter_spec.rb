require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/versioning/formatters/android_version_formatter'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/versioning/formatters/version_formatter'

describe WPMReleaseToolkit::Versioning::AndroidVersionFormatter do
  describe 'formats a beta version number with the correct format' do
    it 'raises an error when the build number is 0' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 0)
      formatter = described_class.new(version)

      expect { formatter.beta_version }
        .to raise_error(
          FastlaneCore::Interface::FastlaneError,
          'The build number of a beta version must be 1 or higher'
        )
    end

    it 'returns a beta version number when provided with a release version object' do
      version = Fastlane::Models::AppVersion.new(1, 2, 0, 4)
      formatter = described_class.new(version)
      formatted_version = formatter.beta_version

      expect(formatted_version.to_s).to eq('1.2-rc-4')
    end

    it 'returns a beta version number when provided with a patch/hotfix version object' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
      formatter = described_class.new(version)
      formatted_version = formatter.beta_version

      expect(formatted_version.to_s).to eq('1.2.3-rc-4')
    end
  end
end
