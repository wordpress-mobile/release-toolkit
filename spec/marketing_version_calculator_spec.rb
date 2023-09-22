require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::MarketingVersionCalculator do
  describe 'calculates the next release version when using marketing versioning' do
    context 'when the minor version is not 9' do
      it 'raises an error when the minor version is greater than 9' do
        version = Fastlane::Models::AppVersion.new(13, 10, 1, 1)
        expect do
          described_class.new.next_release_version(after: version)
        end.to raise_error(FastlaneCore::Interface::FastlaneError), 'Marketing Versioning: The minor version cannot be greater than 9'
      end

      it 'increments the minor version when the minor version is less than 9' do
        version = Fastlane::Models::AppVersion.new(13, 5, 1, 1)
        bumped_version = described_class.new.next_release_version(after: version)
        expect(bumped_version.to_s).to eq('13.6.0.0')
      end
    end

    context 'when the minor number is 9' do
      it 'increments the major version and sets the minor version to 0 ' do
        version = Fastlane::Models::AppVersion.new(13, 9, 1, 1)
        bumped_version = described_class.new.next_release_version(after: version)
        expect(bumped_version.to_s).to eq('14.0.0.0')
      end
    end
  end

  describe 'calculates the previous release version when using marketing versioning' do
    context 'when the minor version is not 0' do
      it 'decrements the minor version' do
        version = Fastlane::Models::AppVersion.new(13, 9, 0, 1)
        previous_version = described_class.new.previous_release_version(before: version)
        expect(previous_version.to_s).to eq('13.8.0.0')
      end
    end

    context 'when the minor version is 0' do
      it 'decrements the major version and sets the minor version to 9' do
        version = Fastlane::Models::AppVersion.new(13, 0, 0, 1)
        previous_version = described_class.new.previous_release_version(before: version)
        expect(previous_version.to_s).to eq('12.9.0.0')
      end
    end
  end
end
