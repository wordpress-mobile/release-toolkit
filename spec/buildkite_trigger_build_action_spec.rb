require 'spec_helper'
require 'buildkit'

describe Fastlane::Actions::BuildkiteTriggerBuildAction do
  let(:buildkit) { Buildkit.new(token: 'test') }

  before do
    allow(Buildkit).to receive(:new).and_return(buildkit)
  end

  context 'when the API responds with state scheduled' do
    it 'returns the new build web URL' do
      expected_url = 'https://fake.url'
      # RuboCop recommends using instance_double, but doing so requires digging into Sawyer::Resource.
      # That object uses metaprogramming to generate accessors for the keys in the JSON response that created it.
      # For the sake of keeping the test simple, let's use a non-verifying double.
      #
      # rubocop:disable RSpec/VerifiedDoubles
      allow(buildkit).to receive(:create_build)
        .and_return(double(state: 'scheduled', web_url: expected_url))
      # rubocop:enable RSpec/VerifiedDoubles

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
      # rubocop:disable RSpec/VerifiedDoubles
      allow(buildkit).to receive(:create_build)
        .and_return(double(state: 'fail', web_url: 'this-is-ignored'))
      # rubocop:enable RSpec/VerifiedDoubles

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
