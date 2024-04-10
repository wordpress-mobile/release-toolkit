require 'spec_helper'

describe Fastlane::Actions::IosCheckBetaDepsAction do
  let(:lockfile_with_external_sources) { File.join(File.dirname(__FILE__), 'test-data', 'Podfile-with-external-sources.lock') }
  let(:lockfile_without_external_sources) { File.join(File.dirname(__FILE__), 'test-data', 'Podfile-without-external-sources.lock') }

  def violation_message(**pods)
    list = pods.map do |pod, reason|
      " - #{pod} (currently points to #{reason})\n"
    end
    Fastlane::Actions::IosCheckBetaDepsAction::NON_STABLE_PODS_MESSAGE + list.join
  end

  before do
    allow(FastlaneCore::UI).to receive(:important)
  end

  it 'reports Pods referenced by commits, branches and -beta|-rc by default' do
    expected_violations = {
      'Gridicons' => '-beta|-rc',
      'NSURL+IDN' => '-beta|-rc',
      'WordPressAuthenticator' => 'commit',
      'WordPressUI' => 'branch'
    }
    expected_message = violation_message(**expected_violations)
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_with_external_sources
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
      lockfile: lockfile_with_external_sources,
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
      lockfile: lockfile_with_external_sources,
      report_branches: false
    )

    expect(result[:pods]).to eq(expected_violations)
    expect(result[:message]).to eq(expected_message)
  end

  it 'does not report Pods referenced by *-beta nor *-rc if regex is empty' do
    expected_violations = {
      'WordPressAuthenticator' => 'commit',
      'WordPressUI' => 'branch'
    }
    expected_message = violation_message(**expected_violations)
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_with_external_sources,
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
      lockfile: lockfile_with_external_sources,
      report_version_pattern: '.*-rc-\d'
    )

    expect(result[:pods]).to eq(expected_violations)
    expect(result[:message]).to eq(expected_message)
  end

  it 'raises user_error! if regex is invalid' do
    expect do
      run_described_fastlane_action(
        lockfile: lockfile_with_external_sources,
        report_version_pattern: '*-rc-\d'
      )
    end.to raise_exception(FastlaneCore::Interface::FastlaneError, 'Invalid regex pattern: `*-rc-\d`')
  end

  it 'does not report any error if everything is disabled' do
    expected_message = Fastlane::Actions::IosCheckBetaDepsAction::ALL_PODS_STABLE_MESSAGE
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    result = run_described_fastlane_action(
      lockfile: lockfile_with_external_sources,
      report_commits: false,
      report_branches: false,
      report_version_pattern: ''
    )

    expect(result[:pods]).to eq({})
    expect(result[:message]).to eq(expected_message)
  end

  it 'does not report any error if all pods resolve to stable versions' do
    expected_message = Fastlane::Actions::IosCheckBetaDepsAction::ALL_PODS_STABLE_MESSAGE
    expect(FastlaneCore::UI).to receive(:important).with(expected_message)

    # Note how, in `Podfile-without-external-sources.lock`, pods like `WordPressAuthenticator`
    # do have a *dependency constraint* on `WordPressShared (~> 2.1-beta)`, but `WordPressShared`
    # ends up being resolved to `2.3.1` so this is ok. This test thus also ensure that we do
    # NOT flag `(~> *-beta)` strings found in constraints, but only from *resolved* versions.
    result = run_described_fastlane_action(
      lockfile: lockfile_without_external_sources
    )

    expect(result[:pods]).to eq({})
    expect(result[:message]).to eq(expected_message)
  end
end
