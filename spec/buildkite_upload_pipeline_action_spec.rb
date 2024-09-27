require 'spec_helper'

describe Fastlane::Actions::BuildkiteUploadPipelineAction do
  let(:pipeline_file) { 'path/to/pipeline.yml' }
  let(:branch) { 'feature-branch' }
  let(:commit) { 'abc123' }
  let(:commit_default) { Fastlane::Actions::BuildkiteUploadPipelineAction::DEFAULT_COMMIT }
  let(:env_file) { 'path/to/env_file' }
  let(:env_file_default) { Fastlane::Actions::BuildkiteUploadPipelineAction::DEFAULT_ENV_FILE }

  before do
    allow(File).to receive(:exist?).with(anything)
    allow(ENV).to receive(:[]).with(anything)
    allow(ENV).to receive(:[]).with('BUILDKITE').and_return('true')
  end

  describe 'parameter validation' do
    it 'raises an error when pipeline_file is not provided' do
      expect do
        run_described_fastlane_action(branch: branch)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /pipeline_file/)
    end

    it 'raises an error when pipeline_file does not exist' do
      allow(File).to receive(:exist?).with(pipeline_file).and_return(false)
      expect do
        run_described_fastlane_action(
          pipeline_file: pipeline_file,
          branch: branch
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Pipeline file not found/)
    end

    it 'raises an error when both branch and commit are provided' do
      allow(File).to receive(:exist?).with(pipeline_file).and_return(true)
      expect do
        run_described_fastlane_action(
          pipeline_file: pipeline_file,
          branch: branch,
          commit: commit
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /You should not provide both `branch` and `commit`/)
    end

    it 'uses the default value for commit when not provided' do
      allow(File).to receive(:exist?).with(pipeline_file).and_return(true)
      expect(Fastlane::Action).to receive(:sh).with(
        { 'BUILDKITE_BRANCH' => branch, 'BUILDKITE_COMMIT' => commit_default },
        'buildkite-agent', 'pipeline', 'upload', pipeline_file
      )
      expect_upload_pipeline_message

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch
      )
    end

    it 'uses the provided value for the commit' do
      allow(File).to receive(:exist?).with(pipeline_file).and_return(true)
      expect(Fastlane::Action).to receive(:sh).with(
        { 'BUILDKITE_COMMIT' => commit },
        'buildkite-agent', 'pipeline', 'upload', pipeline_file
      )
      expect_upload_pipeline_message(expected_branch: nil, expected_commit: commit)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        commit: commit
      )
    end

    it 'raises an error when not running on Buildkite' do
      allow(File).to receive(:exist?).with(pipeline_file).and_return(true)
      allow(ENV).to receive(:[]).with('BUILDKITE').and_return(nil)

      expect do
        run_described_fastlane_action(
          pipeline_file: pipeline_file,
          branch: branch
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /This action can only be called from a Buildkite CI build/)
    end
  end

  describe 'pipeline upload' do
    before do
      allow(File).to receive(:exist?).with(pipeline_file).and_return(true)
    end

    it 'calls the right command to upload the pipeline without env_file' do
      expect(Fastlane::Action).to receive(:sh).with(
        { 'BUILDKITE_BRANCH' => branch, 'BUILDKITE_COMMIT' => commit_default },
        'buildkite-agent', 'pipeline', 'upload', pipeline_file
      )
      expect_upload_pipeline_message

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch
      )
    end

    it 'calls the right command to upload the pipeline with env_file' do
      allow(File).to receive(:exist?).with(env_file).and_return(true)
      expect(Fastlane::Action).to receive(:sh).with(
        { 'BUILDKITE_BRANCH' => branch, 'BUILDKITE_COMMIT' => commit_default },
        "source #{env_file.shellescape} && buildkite-agent pipeline upload #{pipeline_file.shellescape}"
      )
      expect_upload_pipeline_message
      expect(Fastlane::UI).to receive(:message).with(/Sourcing environment file beforehand: #{env_file}/)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        env_file: env_file,
        branch: branch
      )
    end

    it 'skips sourcing env_file when it does not exist' do
      non_existent_env_file = 'path/to/non_existent_env_file'
      allow(File).to receive(:exist?).with(non_existent_env_file).and_return(false)
      expect(Fastlane::Action).to receive(:sh).with(
        { 'BUILDKITE_BRANCH' => branch, 'BUILDKITE_COMMIT' => commit_default },
        'buildkite-agent', 'pipeline', 'upload', pipeline_file
      )
      expect(Fastlane::UI).not_to receive(:message).with(/Sourcing environment file/)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        env_file: non_existent_env_file,
        branch: branch
      )
    end

    it 'uses a default env_file when no env_file is provided' do
      allow(File).to receive(:exist?).with(env_file_default).and_return(true)
      expect(Fastlane::Action).to receive(:sh).with(
        { 'BUILDKITE_BRANCH' => branch, 'BUILDKITE_COMMIT' => commit_default },
        "source #{env_file_default} && buildkite-agent pipeline upload #{pipeline_file.shellescape}"
      )
      expect_upload_pipeline_message
      expect(Fastlane::UI).to receive(:message).with(/Sourcing environment file beforehand: #{env_file_default}/)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch
      )
    end
  end

  describe 'error handling' do
    it 'raises an error when the pipeline upload fails' do
      allow(File).to receive(:exist?).with(pipeline_file).and_return(true)
      allow(Fastlane::Action).to receive(:sh).and_raise(StandardError.new('Upload failed'))

      expect do
        run_described_fastlane_action(
          pipeline_file: pipeline_file,
          branch: branch
        )
      end.to raise_error(StandardError, 'Upload failed')
    end
  end

  def expect_upload_pipeline_message(expected_branch: branch, expected_commit: commit_default)
    expect(Fastlane::UI).to receive(:message).with(
      "Uploading pipeline on #{pipeline_file}#{expected_branch ? ", branch #{expected_branch}" : ''}, commit #{expected_commit}"
    )
  end
end
