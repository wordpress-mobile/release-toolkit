require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::RCNotationVersionFormatter do
  describe 'parses a version string' do
    it 'returns a version object when provided with a release version name string' do
      version = described_class.new.parse('1.2.3')
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.patch).to eq(3)
      expect(version.build_number).to eq(0)
    end

    it 'returns a version object when provided with a beta version name string' do
      version = described_class.new.parse('1.2.3-rc-4')
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.patch).to eq(3)
      expect(version.build_number).to eq(4)
    end
  end

  describe 'formats a beta version number with the correct format' do
    it 'raises an error when the build number is 0' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 0)

      expect { described_class.new.beta_version(version) }
        .to raise_error(
          FastlaneCore::Interface::FastlaneError,
          'The build number of a beta version must be 1 or higher'
        )
    end

    it 'returns a beta version number when provided with a release version object' do
      version = Fastlane::Models::AppVersion.new(1, 2, 0, 4)
      formatted_version = described_class.new.beta_version(version)

      expect(formatted_version).to eq('1.2-rc-4')
    end

    it 'returns a beta version number when provided with a patch/hotfix version object' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
      formatted_version = described_class.new.beta_version(version)

      expect(formatted_version).to eq('1.2.3-rc-4')
    end
  end
end
