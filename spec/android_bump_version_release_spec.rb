require_relative 'spec_helper'

describe Fastlane::Actions::AndroidBumpVersionReleaseAction do
  context 'when evaluating the build_gradle_path and version_properties_path values' do
    it 'fails if neither is given' do
      expect { run_described_fastlane_action({}) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, 'Either a build_gradle_path or version_properties_path must be specified.')
    end

    it 'show the conflicting options message if both are given' do
      expect do
        run_described_fastlane_action(
          build_gradle_path: 'some',
          version_properties_path: 'some other'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "Unresolved conflict between options: 'build_gradle_path' and 'version_properties_path'")
    end
  end
end
