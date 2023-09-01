require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::FindPreviousTagAction do
  before do
    allow(Fastlane::Actions).to receive(:sh).with(*%w[git fetch --tags --force])
  end

  def stub_current_commit_tag(tag)
    allow(Fastlane::Actions).to receive(:sh)
      .with('git describe --tags --exact-match 2>/dev/null || true')
      .and_return("#{tag || ''}\n")
  end

  def stub_main_command(expected_command, stdout:, success: true)
    allow(Fastlane::Actions).to receive(:sh).with(*expected_command).and_yield(
      instance_double(Process::Status, success?: success),
      "#{stdout}\n",
      '_(unused)_'
    )
  end

  it 'finds absolute previous tag if no pattern is provided' do
    # Arrange
    stub_current_commit_tag(nil)
    stub_main_command(
      %w[git describe --tags --abbrev=0],
      stdout: '12.3'
    )
    # Act
    tag = run_described_fastlane_action({})
    # Assert
    expect(tag).to eq('12.3')
  end

  it 'finds matching previous tag if a pattern is provided' do
    # Arrange
    stub_current_commit_tag(nil)
    stub_main_command(
      %w[git describe --tags --abbrev=0 --match 12.*],
      stdout: '12.3'
    )
    # Act
    tag = run_described_fastlane_action(
      pattern: '12.*'
    )
    # Assert
    expect(tag).to eq('12.3')
  end

  it 'excludes the current commit\'s tag if it has one' do
    # Arrange
    stub_current_commit_tag('12.3')
    stub_main_command(
      %w[git describe --tags --abbrev=0 --match 12.* --exclude 12.3],
      stdout: '12.2'
    )
    # Act
    tag = run_described_fastlane_action(
      pattern: '12.*'
    )
    # Assert
    expect(tag).to eq('12.2')
  end

  it 'returns nil if no previous commit could be found' do
    # Arrange
    stub_current_commit_tag(nil)
    stub_main_command(
      %w[git describe --tags --abbrev=0 --match 12.*],
      stdout: 'fatal: No names found, cannot describe anything.',
      success: false
    )
    # Act
    tag = run_described_fastlane_action(
      pattern: '12.*'
    )
    # Assert
    expect(tag).to be_nil
  end
end
