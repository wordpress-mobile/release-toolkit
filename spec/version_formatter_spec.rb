require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::VersionFormatter do
  describe 'formats the version number' do
    context 'when the patch version is 0' do
      it 'returns a version string with the major and minor versions' do
        version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
        release_version = described_class.new.release_version(version)
        expect(release_version).to eq('19.3.1')
      end
    end

    context 'when the patch version is not 0' do
      it 'returns a version string with the major, minor, and patch versions' do
        version = Fastlane::Models::AppVersion.new(19, 3, 0, 1)
        release_version = described_class.new.release_version(version)
        expect(release_version).to eq('19.3')
      end
    end
  end
end
