# frozen_string_literal: true

require 'spec_helper'
require_relative 'release_scan_helpers'

describe ReleaseScan::Report do
  let(:scanned_at) { '2026-11-02 00:00 UTC' }

  it 'renders findings redacted, with coverage notes' do
    token = ReleaseScanHelpers::TOKEN
    finding = ReleaseScan::Finding.new(
      rule: 'shaped-value-beside-url', severity: 'critical', location: 'App', offset: 32,
      summary: 'ZdTe…EF', digest: 'abc123', detail: 'Shaped value packed beside a URL.'
    )
    result = ReleaseScan::ScanResult.new(label: 'App.ipa', status: 'scanned', reason: '', findings: [finding], notes: ['a note'])
    text = described_class.render(result, scanned_at)
    expect(text).not_to include(token)
    expect(text).to include('ZdTe…EF', '## Findings', 'a note')
    expect(text).not_to include('## Error')
  end

  it 'shows the error' do
    result = ReleaseScan::ScanResult.new(label: 'App.ipa', status: 'error', reason: 'B: cannot read', findings: [], notes: [])
    expect(described_class.render(result, scanned_at)).to include('B: cannot read')
  end
end
