# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::BuildkiteAddTriggerStepAction do
  let(:pipeline_file) { 'test-pipeline.yml' }
  let(:build_name) { 'test-pipeline' }
  let(:branch) { 'test-branch' }
  let(:message) { 'Test Build' }
  let(:environment) { { 'TEST_VAR' => 'test-value' } }
  let(:buildkite_pipeline_slug) { 'test-pipeline' }
  let(:async) { false }
  let(:label) { nil } # Will use default

  def expected_yaml(
    pipeline_file: self.pipeline_file,
    build_name: self.build_name,
    branch: self.branch,
    message: self.message,
    extra_env: environment,
    buildkite_pipeline_slug: self.buildkite_pipeline_slug,
    async: self.async,
    label: self.label
  )
    # Calculate the label based on whether a custom one was provided
    actual_label = label || ":buildkite: Trigger #{build_name} on #{branch}"

    # Merge the environment with PIPELINE, ensuring PIPELINE is always set correctly
    actual_env = extra_env.merge('PIPELINE' => pipeline_file)

    {
      'steps' => [
        {
          'trigger' => buildkite_pipeline_slug,
          'label' => actual_label,
          'async' => async,
          'build' => {
            'branch' => branch,
            'message' => message,
            'env' => actual_env
          }
        },
      ]
    }.to_yaml
  end

  before do
    # Mock the git command to return our test branch
    allow(described_class).to receive(:`).with('git rev-parse --abbrev-ref HEAD').and_return(branch)

    # Mock the pipeline upload command to return a success status
    allow(Open3).to receive(:capture3)
      .with('buildkite-agent', 'pipeline', 'upload', stdin_data: anything)
      .and_return(['', '', instance_double(Process::Status, success?: true)])
  end

  context 'when all required parameters are provided' do
    it 'uploads the correct pipeline YAML' do
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'uses the current branch when not provided' do
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'uses a custom label when provided' do
      custom_label = '🚀 Custom Trigger Label'
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(label: custom_label))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async,
        label: custom_label
      )
    end

    it 'uses async: true when specified' do
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(async: true))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: true
      )
    end
  end

  context 'when the pipeline upload fails' do
    it 'raises a user error with the error message' do
      error_message = 'Failed to upload pipeline'
      allow(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml)
        .and_return(['', error_message, instance_double(Process::Status, success?: false)])

      expect(FastlaneCore::UI).to receive(:user_error!).with("Failed to upload pipeline: #{error_message}")

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end
  end

  context 'when required parameters are missing' do
    it 'raises an error when pipeline_file is not provided' do
      expect do
        run_described_fastlane_action(
          branch: branch,
          message: message,
          environment: environment,
          buildkite_pipeline_slug: buildkite_pipeline_slug,
          async: async
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /No value found for 'pipeline_file'/)
    end

    it 'raises an error when buildkite_pipeline_slug is not provided' do
      expect do
        run_described_fastlane_action(
          pipeline_file: pipeline_file,
          branch: branch,
          message: message,
          environment: environment,
          async: async
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /No value found for 'buildkite_pipeline_slug'/)
    end
  end

  context 'when testing parameter default values and custom values' do
    it 'uses the pipeline file basename as message when not provided' do
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(message: build_name))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'uses an empty environment hash when not provided' do
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(extra_env: {}))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'uses async: false when not provided' do
      # This is already tested in the default case, but let's make it explicit
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug
      )
    end

    it 'uses the default label when not provided' do
      # This is already tested in the default case, but let's make it explicit
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml)

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'allows overriding the default message with a custom one' do
      custom_message = 'Custom Build Message'
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(message: custom_message))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: custom_message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'allows overriding the default branch with a custom one' do
      custom_branch = 'custom-branch'
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(branch: custom_branch))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: custom_branch,
        message: message,
        environment: environment,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'allows overriding the default environment with a custom one' do
      custom_env = { 'CUSTOM_VAR' => 'custom-value' }
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(extra_env: custom_env))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: custom_env,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end

    it 'preserves the PIPELINE environment variable even when custom environment is provided' do
      custom_env = { 'CUSTOM_VAR' => 'custom-value', 'PIPELINE' => 'should-be-overridden.yml' }
      expect(Open3).to receive(:capture3)
        .with('buildkite-agent', 'pipeline', 'upload', stdin_data: expected_yaml(extra_env: { 'CUSTOM_VAR' => 'custom-value' }))

      run_described_fastlane_action(
        pipeline_file: pipeline_file,
        branch: branch,
        message: message,
        environment: custom_env,
        buildkite_pipeline_slug: buildkite_pipeline_slug,
        async: async
      )
    end
  end
end
