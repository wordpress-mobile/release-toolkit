# frozen_string_literal: true

require 'spec_helper'
require_relative 'release_scan_helpers'

describe ReleaseScan::Extract do
  include ReleaseScanHelpers

  def with_archive(entries)
    Dir.mktmpdir do |tmp|
      root = Pathname.new(tmp)
      archive = root.join('a.zip')
      write_zip(archive, entries)
      yield archive, root
    end
  end

  it 'round-trips an IPA into findings' do
    with_archive('Payload/App.app/App' => packed) do |archive, root|
      described_class.safe_extract(archive, root.join('out'))
      dumps = ReleaseScan::Gitleaks::StringDumps.new(root.join('strings'))
      findings, scanned, = ReleaseScan::Scan.scan_tree(root.join('out'), 'App.ipa', dumps)
      expect(scanned).to be_positive
      expect(dumps.any?).to be true
      expect(rules_of(findings)).to include('shaped-value-beside-url')
    end
  end

  it 'rejects members that escape the destination' do
    with_archive('../evil.txt' => 'nope') do |archive, root|
      expect { described_class.safe_extract(archive, root.join('nested', 'out')) }.to raise_error(ArgumentError)
      expect(root.join('nested', 'evil.txt')).not_to exist
    end
  end

  it 'stops at the size budget' do
    with_archive('big' => 'x' * 100) do |archive, root|
      budget = described_class::Budget.new(max_bytes: 10)
      expect { described_class.safe_extract(archive, root.join('out'), budget: budget) }
        .to raise_error(described_class::LimitExceeded)
    end
  end

  it 'stops at the entry budget' do
    with_archive('one' => 'x', 'two' => 'y') do |archive, root|
      budget = described_class::Budget.new(max_entries: 1)
      expect { described_class.safe_extract(archive, root.join('out'), budget: budget) }
        .to raise_error(described_class::LimitExceeded)
    end
  end

  it 'stops copying a directory at the size budget' do
    Dir.mktmpdir do |tmp|
      source = Pathname.new(tmp).join('tree')
      source.mkpath
      source.join('big').write('x' * 100)
      budget = described_class::Budget.new(max_bytes: 10)
      expect { described_class.copy_tree(source, Pathname.new(tmp).join('out'), budget: budget) }
        .to raise_error(described_class::LimitExceeded)
    end
  end
end
