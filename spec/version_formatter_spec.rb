require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/formatters/version_formatter'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'

describe Fastlane::Formatters::VersionFormatter do
  describe 'formats the version number' do
    context 'when the patch version is 0' do
      it 'returns a version string with the major and minor versions' do
        version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
        release_version_formatter = described_class.new(version)
        release_version = release_version_formatter.release_version
        expect(release_version).to eq('19.3.1')
      end
    end

    context 'when the patch version is not 0' do
      it 'returns a version string with the major, minor, and patch versions' do
        version = Fastlane::Models::AppVersion.new(19, 3, 0, 1)
        release_version_formatter = described_class.new(version)
        release_version = release_version_formatter.release_version
        expect(release_version).to eq('19.3')
      end
    end
  end
end
