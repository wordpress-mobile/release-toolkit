require 'spec_helper'
require 'buildkit'

FakeResponse = Struct.new(:state, :web_url)

describe Fastlane::Actions::BuildkiteTriggerBuildAction do
  let(:buildkit) { Buildkit.new(token: 'test') }

  before do
    allow(Buildkit).to receive(:new).and_return(buildkit)
  end

  context 'when the API responds with state scheduled' do
    it 'returns the new build web URL' do
      expected_url = 'https://fake.url'
      allow(buildkit).to receive(:create_build)
        .and_return(FakeResponse.new('scheduled', expected_url))

      url = run_described_fastlane_action(
        branch: 'branch',
        commit: '1a2b3c',
        pipeline_file: 'pipeline.yml',
        buildkite_organization: 'org',
        buildkite_pipeline: 'project'
      )

      expect(url).to eq expected_url
    end
  end

  context 'when the API responds with a state other than scheduled' do
    it 'raises an error' do
      allow(buildkit).to receive(:create_build)
        .and_return(FakeResponse.new('fail', 'this-is-ignored'))

      # Don't care about the error message
      expect(FastlaneCore::UI).to receive(:crash!)

      run_described_fastlane_action(
        branch: 'branch',
        commit: '1a2b3c',
        pipeline_file: 'pipeline.yml',
        buildkite_organization: 'org',
        buildkite_pipeline: 'project'
      )
    end
  end
end
