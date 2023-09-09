#require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/bumpers/date_version_bumper'
require_relative './spec_helper'

describe Fastlane::Bumper::VersionBumper do
  describe 'bumps the version number when using date versioning' do
    context 'when the current month is not December' do
      it 'increments the minor version number without prompting the user' do
        allow(Time).to receive(:now).and_return(Time.new(2024, 4, 15))
        version = '1995.5'
        next_version = described_class.calc_next_release_version(version, 'calendar')
        expect(next_version).to eq('1995.6')
      end
    end

    context 'when the current month is December' do
      context 'when the release is the first release of the next year' do
        it 'increments the major version number and sets the minor version number to 1' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 3))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(true)
          version = Version.new(1999, 30, 1, 2)
          bumper = described_class.new(version)
          bumped_version = bumper.bump_minor_version
          expect(bumped_version.to_s).to eq('2000.31.0.0')
        end
      end

      context 'when the release is not the first release of the next year' do
        it 'increments the minor version number' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 1))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(false)
          version = Version.new(1999, 30, 1, 2)
          bumper = described_class.new(version)
          bumped_version = bumper.bump_minor_version
          expect(bumped_version.to_s).to eq('1999.31.0.0')
        end
      end
    end
  end
end
