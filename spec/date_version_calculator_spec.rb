require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::DateVersionCalculator do
  describe 'calculates the next release version when using date versioning' do
    context 'when the current month is not December' do
      it 'increments the minor version number without prompting the user' do
        allow(Time).to receive(:now).and_return(Time.new(2024, 4, 15))
        version = Fastlane::Models::AppVersion.new(2024, 13, 1, 1)
        bumped_version = described_class.new.next_release_version(version: version)
        # Test that the original version is not modified
        expect(version.to_s).to eq('2024.13.1.1')
        expect(bumped_version.to_s).to eq('2024.14.0.0')
      end
    end

    context 'when the current month is December' do
      context 'when the release is the first release of the next year' do
        it 'increments the major version number and sets the minor version number to 1' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 3))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(true)
          version = Fastlane::Models::AppVersion.new(2023, 30, 1, 2)
          bumped_version = described_class.new.next_release_version(version: version)
          # Test that the original version is not modified
          expect(version.to_s).to eq('2023.30.1.2')
          expect(bumped_version.to_s).to eq('2024.1.0.0')
        end
      end

      context 'when the release is not the first release of the next year' do
        it 'increments the minor version number' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 1))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(false)
          version = Fastlane::Models::AppVersion.new(2023, 30, 1, 2)
          bumped_version = described_class.new.next_release_version(version: version)
          # Test that the original version is not modified
          expect(version.to_s).to eq('2023.30.1.2')
          expect(bumped_version.to_s).to eq('2023.31.0.0')
        end
      end
    end
  end
end
