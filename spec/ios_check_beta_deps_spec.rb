require 'spec_helper'

describe Fastlane::Actions::IosCheckBetaDepsAction do
  let(:lockfile_fixture_path) { File.join(File.dirname(__FILE__), 'test-data', 'Podfile.lock') }

  def violation_message(**pods)
    list = pods.map do |pod, reason|
      " - #{pod} (currently points to #{reason})\n"
    end
    Fastlane::Actions::IosCheckBetaDepsAction::NON_STABLE_PODS_MESSAGE + list.join
  end

  before do
    allow(FastlaneCore::UI).to receive(:important)
  end

  it 'reports Pods referenced by commits, branches and -beta by default' do
    expected_violations = {
      'Gridicons' => '-beta|-rc',
      'NSURL+IDN' => '-beta|-rc',
      'WordPressAuthenticator' => 'commit',
      'WordPressUI' => 'branch'
    }
    expected_message = violation_message(**expected_violations)
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_fixture_path
    )

    expect(result[:pods]).to eq(expected_violations)
    expect(result[:message]).to eq(expected_message)
  end

  it 'does not report Pods referenced by commits if option disabled' do
    expected_violations = {
      'Gridicons' => '-beta|-rc',
      'NSURL+IDN' => '-beta|-rc',
      'WordPressUI' => 'branch'
    }
    expected_message = violation_message(**expected_violations)
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_fixture_path,
      report_commits: false
    )

    expect(result[:pods]).to eq(expected_violations)
    expect(result[:message]).to eq(expected_message)
  end

  it 'does not report Pods referenced by branch if option disabled' do
    expected_violations = {
      'Gridicons' => '-beta|-rc',
      'NSURL+IDN' => '-beta|-rc',
      'WordPressAuthenticator' => 'commit'
    }
    expected_message = violation_message(**expected_violations)
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_fixture_path,
      report_branches: false
    )

    expect(result[:pods]).to eq(expected_violations)
    expect(result[:message]).to eq(expected_message)
  end

  it 'does not report Pods referenced by *-beta if regex is empty' do
    expected_violations = {
      'WordPressAuthenticator' => 'commit',
      'WordPressUI' => 'branch'
    }
    expected_message = violation_message(**expected_violations)
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_fixture_path,
      report_version_pattern: ''
    )

    expect(result[:pods]).to eq(expected_violations)
    expect(result[:message]).to eq(expected_message)
  end

  it 'report Pods referenced by version matching custom regex' do
    expected_violations = {
      'NSURL+IDN' => '.*-rc-\d',
      'WordPressAuthenticator' => 'commit',
      'WordPressUI' => 'branch'
    }
    expected_message = violation_message(**expected_violations)
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_fixture_path,
      report_version_pattern: '.*-rc-\d'
    )

    expect(result[:pods]).to eq(expected_violations)
    expect(result[:message]).to eq(expected_message)
  end

  it 'does not report any error if everything is disabled' do
    expected_message = Fastlane::Actions::IosCheckBetaDepsAction::ALL_PODS_STABLE_MESSAGE
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_fixture_path,
      report_commits: false,
      report_branches: false,
      report_version_pattern: ''
    )

    expect(result[:pods]).to eq({})
    expect(result[:message]).to eq(expected_message)
  end

  it 'raises user_error! if regex is invalid' do
    expect do
      run_described_fastlane_action(
        lockfile: lockfile_fixture_path,
        report_version_pattern: '*-rc-\d'
      )
    end.to raise_exception(FastlaneCore::Interface::FastlaneError, 'Invalid regex pattern: `*-rc-\d`')
  end
end
