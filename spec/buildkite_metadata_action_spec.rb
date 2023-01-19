require 'spec_helper'

describe Fastlane::Actions::BuildkiteMetadataAction do
  it 'calls the right command to set a single metadata' do
    expect(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'set', 'foo', 'bar')

    res = run_described_fastlane_action(set: { foo: 'bar' })
    expect(res).to be_nil
  end

  it 'calls the commands as many times as necessary when we want to set multiple metadata at once' do
    expect(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'set', 'key1', 'value1')
    expect(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'set', 'key2', 'value2')

    metadata = {
      key1: 'value1',
      key2: 'value2'
    }
    run_described_fastlane_action(set: metadata)
  end

  it 'calls the right command to get the value of metadata, and returns the right value' do
    expect(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'get', 'foo')
    allow(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'get', 'foo').and_return('foo value')

    res = run_described_fastlane_action(get: 'foo')
    expect(res).to eq('foo value')
  end

  it 'allows both setting and getting metadata in the same call' do
    # Might not be the main way we intend to use this action… but it's still supported.
    expect(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'set', 'key1', 'value1')
    expect(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'set', 'key2', 'value2')
    expect(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'get', 'key3')
    allow(Fastlane::Action).to receive(:sh).with('buildkite-agent', 'meta-data', 'get', 'key3').and_return('value3')

    new_metadata = {
      key1: 'value1',
      key2: 'value2'
    }
    res = run_described_fastlane_action(set: new_metadata, get: 'key3')

    expect(res).to eq('value3')
  end
end
