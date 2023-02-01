require 'spec_helper'

describe Fastlane::Actions::BuildkiteAnnotateAction do
  describe '`style` parameter validation' do
    it 'errors if we use an invalid style' do
      expect(FastlaneCore::UI).to receive(:user_error!).with('Invalid value `failure` for parameter `style`. Valid values are: success, info, warning, error')

      run_described_fastlane_action(
        context: 'ctx',
        style: 'failure',
        message: 'Fake message'
      )
    end

    %w[success info warning error].each do |style|
      it "accepts `#{style}` as a valid style" do
        expect(FastlaneCore::UI).not_to receive(:user_error!)
        cmd = run_described_fastlane_action(
          context: 'ctx',
          style: style,
          message: 'message'
        )
        expect(cmd).to eq("buildkite-agent annotate --context ctx --style #{style} message")
      end
    end

    it 'accepts `nil` as a valid style' do
      expect(FastlaneCore::UI).not_to receive(:user_error!)
      cmd = run_described_fastlane_action(
        context: 'ctx',
        message: 'message'
      )
      expect(cmd).to eq('buildkite-agent annotate --context ctx message')
    end
  end

  describe 'annotation creation' do
    it 'generates the right command to create an annotation when message is provided' do
      cmd = run_described_fastlane_action(
        context: 'ctx',
        style: 'warning',
        message: 'message'
      )
      expect(cmd).to eq('buildkite-agent annotate --context ctx --style warning message')
    end

    it 'properly escapes the message and context' do
      cmd = run_described_fastlane_action(
        context: 'some ctx',
        style: 'warning',
        message: 'a <b>nice</b> message; with fun characters & all…'
      )
      expect(cmd).to eq('buildkite-agent annotate --context some\ ctx --style warning a\ \<b\>nice\</b\>\ message\;\ with\ fun\ characters\ \&\ all\…')
    end

    it 'falls back to Buildkite\'s default `context` when none is provided' do
      cmd = run_described_fastlane_action(
        style: 'warning',
        message: 'a nice message'
      )
      expect(cmd).to eq('buildkite-agent annotate --style warning a\ nice\ message')
    end

    it 'falls back to Buildkite\'s default `style` when none is provided' do
      cmd = run_described_fastlane_action(
        context: 'my-ctx',
        message: 'a nice message'
      )
      expect(cmd).to eq('buildkite-agent annotate --context my-ctx a\ nice\ message')
    end
  end

  describe 'annotation deletion' do
    it 'generates the right command to delete an annotation when no message is provided' do
      cmd = run_described_fastlane_action(
        context: 'some ctx',
        message: nil
      )
      expect(cmd).to eq('buildkite-agent annotation remove --context some\ ctx || true')
    end
  end
end
