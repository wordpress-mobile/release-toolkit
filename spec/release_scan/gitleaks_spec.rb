# frozen_string_literal: true

require 'spec_helper'
require_relative 'release_scan_helpers'

describe ReleaseScan::Gitleaks do
  include ReleaseScanHelpers

  def dumps_in(tmp)
    described_class::StringDumps.new(Pathname.new(tmp).join('strings'))
  end

  def stub_gitleaks(report:, stderr: '', success: true)
    allow(Open3).to receive(:capture3) do |*arguments|
      path = arguments[arguments.index('-r') + 1]
      Pathname.new(path).write(report) if report
      ['', stderr, instance_double(Process::Status, success?: success)]
    end
  end

  describe '.severity' do
    it 'drops generic rules and demotes client SDK rules' do
      expect(described_class.severity('generic-api-key')).to be_nil
      expect(described_class.severity('private-key')).to eq('info')
      expect(described_class.severity('gcp-api-key')).to eq('info')
      expect(described_class.severity('aws-access-key-id')).to eq('critical')
    end
  end

  describe described_class::StringDumps do
    it 'writes private files named independently of the member' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp).join('extracted')
        root.join('a').mkpath
        root.join('a__b').binwrite(binary("first value\0"))
        root.join('a', 'b').binwrite(binary("second value\0"))
        dumps = described_class.new(Pathname.new(tmp).join('strings'))
        _, scanned, = ReleaseScan::Scan.scan_tree(root, 'archive', dumps)
        files = dumps.directory.children.sort
        expect(scanned).to eq(2)
        expect(files.map { |file| file.basename.to_s }).to eq(%w[000001.txt 000002.txt])
        expect(files.first.stat.mode & 0o777).to eq(0o600)
        expect(dumps.directory.stat.mode & 0o777).to eq(0o700)
      end
    end

    it 'maps a line back to its member and byte offset' do
      Dir.mktmpdir do |tmp|
        dumps = described_class.new(Pathname.new(tmp).join('strings'))
        dumps.add_table('bin/App', [[100, 'firstvalue'], [500, 'secondvalue']])
        dumps.add_text('config.txt', "one\ntwo\nthree\n")
        expect(dumps.locate('/any/where/000001.txt', 2)).to eq(['bin/App', 500])
        expect(dumps.locate('000002.txt', 3)).to eq(['config.txt', 8])
      end
    end
  end

  describe '.run with the real binary' do
    before { skip 'gitleaks is not installed' unless described_class.available? }

    it 'redacts what it finds' do
      key = ReleaseScanHelpers::AWS_KEY
      Dir.mktmpdir do |tmp|
        dumps = dumps_in(tmp)
        dumps.add_text('config.txt', "id=#{key}\n")
        findings = described_class.run(dumps, 'app')
        expect(rules_of(findings)).to include(a_string_including('aws'))
        listed = findings.reject { |finding| finding.rule == 'gitleaks-suppressed' }
        expect(listed.map(&:summary).uniq).to eq(['redacted-by-gitleaks'])
        expect(findings.inspect).not_to include(key)
      end
    end

    it 'sees paths its default allowlist would hide, and reports the member and offset' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp).join('extracted')
        root.join('res', 'node_modules', 'x').mkpath
        root.join('res', 'node_modules', 'x', 'index.js').write("one\ntwo\nid=#{ReleaseScanHelpers::AWS_KEY}\n")
        dumps = dumps_in(tmp)
        ReleaseScan::Scan.scan_tree(root, 'app', dumps)
        hit = described_class.run(dumps, 'app').find { |finding| finding.rule.include?('aws') }
        expect(hit.location).to eq('app:res/node_modules/x/index.js')
        expect(hit.offset).to eq(8)
      end
    end

    it 'agrees with the built-in vendor rules' do
      Dir.mktmpdir do |tmp|
        dumps = dumps_in(tmp)
        vendor_samples.each { |rule, sample| dumps.add_text(rule, "value=\"#{sample}\"\n") }
        rules = described_class.run(dumps, 'app').map { |finding| finding.rule.delete_prefix('gitleaks:') }
        expect(rules).to include(*vendor_samples.keys)
      end
    end
  end

  describe '.run with a stubbed binary' do
    before { allow(described_class).to receive(:available?).and_return(true) }

    it 'counts generic hits, and copies no secret field' do
      payload = [
        { 'RuleID' => 'generic-api-key', 'File' => 'a.txt', 'StartLine' => 1, 'Secret' => 'super-secret-value', 'Description' => 'Generic' },
        { 'RuleID' => 'aws-access-key-id', 'File' => 'a.txt', 'StartLine' => 2, 'Secret' => 'should-stay-in-the-report-only', 'Description' => 'AWS' },
      ]
      stub_gitleaks(report: JSON.generate(payload))
      Dir.mktmpdir do |tmp|
        findings = described_class.run(dumps_in(tmp), 'app')
        expect(findings.inspect).not_to include('super-secret-value')
        expect(findings.inspect).not_to include('should-stay-in-the-report-only')
        expect(rules_of(findings)).to include('gitleaks:aws-access-key-id')
        expect(findings.find { |finding| finding.rule == 'gitleaks-suppressed' }.summary).to eq('1')
      end
    end

    it 'ignores ambient configuration' do
      seen = nil
      allow(Open3).to receive(:capture3) do |*arguments|
        seen = arguments
        Pathname.new(arguments[arguments.index('-r') + 1]).write('[]')
        ['', '', instance_double(Process::Status, success?: true)]
      end
      Dir.mktmpdir do |tmp|
        with_environment('GITLEAKS_CONFIG' => '/tmp/nope.toml', 'GITLEAKS_CONFIG_TOML' => 'x') do
          described_class.run(dumps_in(tmp), 'app')
        end
      end
      expect(seen.first).to eq('GITLEAKS_CONFIG' => nil, 'GITLEAKS_CONFIG_TOML' => nil)
      expect(seen).to include('--ignore-gitleaks-allow', '--no-git')
    end

    it 'raises when the report is not JSON' do
      stub_gitleaks(report: '{')
      Dir.mktmpdir do |tmp|
        expect { described_class.run(dumps_in(tmp), 'app') }.to raise_error(RuntimeError, /not JSON/)
      end
    end

    it 'raises on a nonzero exit even with a report' do
      stub_gitleaks(report: '[]', stderr: 'gitleaks scan failed', success: false)
      Dir.mktmpdir do |tmp|
        expect { described_class.run(dumps_in(tmp), 'app') }.to raise_error(RuntimeError, /gitleaks scan failed/)
      end
    end

    it 'raises when no report was written' do
      stub_gitleaks(report: nil, stderr: 'gitleaks failed badly')
      Dir.mktmpdir do |tmp|
        expect { described_class.run(dumps_in(tmp), 'app') }.to raise_error(RuntimeError, /gitleaks failed badly/)
      end
    end
  end
end
