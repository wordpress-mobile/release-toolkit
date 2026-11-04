# frozen_string_literal: true

require 'spec_helper'
require_relative 'release_scan_helpers'

describe ReleaseScan::CLI do
  include ReleaseScanHelpers

  let(:token) { ReleaseScanHelpers::TOKEN }
  let(:aws_key) { ReleaseScanHelpers::AWS_KEY }

  def with_binary(contents, name: 'App')
    Dir.mktmpdir do |tmp|
      root = Pathname.new(tmp)
      path = root.join(name)
      path.binwrite(contents)
      yield path, root
    end
  end

  it 'stays out of the fastlane plugin load path' do
    expect(Fastlane::Wpmreleasetoolkit.all_classes.grep(/release_scan/)).to be_empty
  end

  describe 'exit status' do
    it 'is 1 on a match, and only redacted reports are written' do
      with_binary(packed) do |path, root|
        expect(run_cli('--output', root.join('out').to_s, path.to_s)).to eq(1)
        written = Dir.glob(root.join('out', '**', '*').to_s).select { |file| File.file?(file) }
        expect(written.map { |file| File.basename(file) }.sort).to eq(%w[report.json report.md])
        written.each { |file| expect(File.read(file)).not_to include(token) }
        expect(root.join('out', 'report.md').read).to include('shaped-value-beside-url')
      end
    end

    it 'is 0 on a clean scan' do
      with_binary(binary("hello from the app\0")) do |path, root|
        expect(run_cli('--output', root.join('out').to_s, path.to_s)).to eq(0)
      end
    end

    it 'is 2 for an archive with nothing to read' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp)
        archive = root.join('App.ipa')
        write_zip(archive, 'Payload/App.app/icon.png' => "\x89PNG".b + ("\0" * 64))
        expect(run_cli('--output', root.join('out').to_s, archive.to_s)).to eq(2)
        expect(root.join('out', 'report.md').read).to include('no binaries')
      end
    end

    it 'is 2 for stray arguments' do
      with_binary(binary("hello from the app\0")) do |path, root|
        expect(run_cli('--output', root.join('out').to_s, path.to_s, 'stray')).to eq(2)
      end
    end

    it 'is 2 without a path' do
      expect(run_cli).to eq(2)
    end

    it 'is 2 for a path that does not exist, with a report' do
      Dir.mktmpdir do |tmp|
        expect(run_cli('--output', tmp, "#{tmp}/nope.ipa")).to eq(2)
        expect(JSON.parse(File.read(File.join(tmp, 'report.json')))['status']).to eq('error')
      end
    end

    it 'is 2 for an empty file' do
      with_binary('') do |path, root|
        expect(run_cli('--output', root.join('out').to_s, path.to_s)).to eq(2)
      end
    end

    it 'is 2 for an oversize file' do
      Dir.mktmpdir do |tmp|
        path = Pathname.new(tmp).join('Huge')
        File.open(path, 'wb') { |file| file.truncate(ReleaseScan::Scan::MAX_FILE_BYTES + 1) }
        expect(run_cli('--output', "#{tmp}/out", path.to_s)).to eq(2)
      end
    end
  end

  describe 'output' do
    it 'defaults to reports under the working directory' do
      Dir.mktmpdir do |tmp|
        path = Pathname.new(tmp).join('App.ipa')
        write_zip(path, 'App' => packed)
        code = Dir.chdir(tmp) { run_cli(path.to_s) }
        expect(code).to eq(1)
        expect(Dir.children(File.join(tmp, 'release-scan')).sort).to eq(%w[report.json report.md])
      end
    end

    it 'works under paths with glob characters or debug symbol names' do
      ['x[1]', '{a,b}', 'dSYMs/out', 'App.dSYM/out'].each do |name|
        Dir.mktmpdir do |tmp|
          root = Pathname.new(tmp)
          archive = root.join('App.ipa')
          write_zip(archive, 'App' => packed)
          expect(run_cli('--output', root.join(name).to_s, archive.to_s)).to eq(1), name
        end
      end
    end

    it 'notes that an installer was only read as outer bytes' do
      with_binary(binary("hello from the app\0"), name: 'Setup.exe') do |path, root|
        expect(run_cli('--output', root.join('out').to_s, path.to_s)).to eq(0)
        expect(root.join('out', 'report.md').read).to include('outer bytes')
      end
    end
  end

  describe 'package members' do
    it 'reads a small dotfile' do
      code, findings, = scan_members('.env' => "A=#{aws_key}\n")
      expect(code).to eq(1)
      expect(rules_of(findings)).to include('aws-access-key-id')
    end

    it 'reads a small binary with no suffix' do
      code, findings, = scan_members('Ext' => "#{"\0" * 32}#{token}\0#{ReleaseScanHelpers::URL}\0#{"\0" * 64}")
      expect(code).to eq(1)
      expect(rules_of(findings)).to include('shaped-value-beside-url')
    end

    it 'reads a UTF-16 strings file' do
      bytes = "\xFF\xFE".b + "#{aws_key}\0\0".encode(Encoding::UTF_16LE).b
      _, findings, = scan_members('Base.lproj/L.strings' => bytes)
      expect(rules_of(findings)).to include('aws-access-key-id')
    end

    it 'reads text with invalid UTF-8 without an error' do
      code, findings, = scan_members('c.txt' => "caf\xE9 #{aws_key}\n".b)
      expect(code).to eq(1)
      expect(rules_of(findings)).to include('aws-access-key-id')
    end

    it 'keeps other findings when one member fails, and leaves no plaintext behind' do
      allow(ReleaseScan::Scan).to receive(:read_bytes).and_wrap_original do |original, path|
        raise 'cannot read' if Pathname.new(path).basename.to_s == 'B'

        original.call(path)
      end
      allow(ReleaseScan::Gitleaks).to receive(:available?).and_return(true)
      gitleaks_ran = false
      allow(ReleaseScan::Gitleaks).to receive(:run) do
        gitleaks_ran = true
        []
      end
      work_directories = []
      allow(Dir).to receive(:mktmpdir).and_wrap_original do |original, *arguments, &block|
        original.call(*arguments) do |directory|
          work_directories << directory
          block.call(directory)
        end
      end

      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp)
        archive = root.join('App.ipa')
        write_zip(archive, 'A' => packed, 'B' => binary('x'), 'C' => packed(ReleaseScanHelpers::SECOND))
        expect(run_default_cli('--output', root.join('out').to_s, archive.to_s)).to eq(2)
        report = JSON.parse(root.join('out', 'report.json').read)
        expect(report['findings'].length).to eq(2)
        expect(report['reason']).to include('B: cannot read')
      end
      expect(gitleaks_ran).to be true
      expect(work_directories.select { |directory| File.exist?(directory) }).to be_empty
    end

    it 'opens a nested zip whatever it is called' do
      code, findings, = scan_members('Payload/App' => binary("clean value\0"), 'split/base.apk' => zip_bytes('lib/App' => packed))
      expect(code).to eq(1)
      expect(findings.find { |finding| finding['rule'] == 'shaped-value-beside-url' }['location']).to include('split/base.apk!/lib/App')
    end

    it 'stops nesting at the depth limit with a note' do
      payload = packed
      (ReleaseScan::Extract::MAX_DEPTH + 1).times { payload = zip_bytes('n.zip' => payload) }
      _, _, report = scan_members('Payload/App' => binary("clean value\0"), 'n.zip' => payload)
      expect(report['notes'].join).to include('nested deeper')
    end

    it 'reads a member that only looks like a zip as bytes' do
      code, findings, report = scan_members('App' => "PK\x03\x04".b + ("\0" * 32) + "#{token}\0#{ReleaseScanHelpers::URL}\0")
      expect(code).to eq(1)
      expect(rules_of(findings)).to include('shaped-value-beside-url')
      expect(report['notes'].join).to include('could not open')
    end

    it 'notes a compressed member' do
      _, _, report = scan_members('Payload/App' => binary("clean value\0"), 'data.tar.gz' => "\x1F\x8B".b + ('x' * 64))
      expect(report['notes'].join).to include('data.tar.gz: may be compressed')
    end

    it 'reads both of two members that differ only by case' do
      _, findings, = scan_members('a/Lib' => packed, 'a/lib' => packed(ReleaseScanHelpers::SECOND))
      expect(rules_of(findings).count('shaped-value-beside-url')).to eq(2)
    end
  end

  describe 'directories' do
    it 'scans an .xcarchive directory, skipping debug symbols' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp)
        expect(run_cli('--output', root.join('out').to_s, build_xcarchive(root).to_s)).to eq(1)
        report = JSON.parse(root.join('out', 'report.json').read)
        expect(report['status']).to eq('scanned')
        locations = report['findings'].select { |finding| finding['rule'] == 'shaped-value-beside-url' }.map { |finding| finding['location'] }
        expect(locations.sort).to eq(
          [
            'App.xcarchive:Products/Applications/App.app/App',
            'App.xcarchive:Products/Applications/App.app/Bundle.zip!/inner/Lib',
          ]
        )
      end
    end

    it 'leaves the directory untouched' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp)
        archive = build_xcarchive(root)
        before = snapshot(archive)
        run_cli('--output', root.join('out').to_s, archive.to_s)
        expect(snapshot(archive)).to eq(before)
      end
    end

    it 'labels the report with the name of the path' do
      Dir.mktmpdir do |tmp|
        archive = build_xcarchive(Pathname.new(tmp))
        Dir.chdir(archive) { run_cli('.', '--output', "#{tmp}/out") }
        expect(JSON.parse(File.read("#{tmp}/out/report.json"))['label']).to eq('App.xcarchive')
      end
    end

    it 'is 2 for an empty directory' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp)
        root.join('Empty.xcarchive').mkpath
        expect(run_cli('--output', root.join('out').to_s, root.join('Empty.xcarchive').to_s)).to eq(2)
      end
    end
  end

  describe 'gitleaks' do
    it 'is an error when it is missing' do
      with_binary(binary("hello from the app\0")) do |path, root|
        code = with_environment('PATH' => '') { run_default_cli('--output', root.join('out').to_s, path.to_s) }
        expect(code).to eq(2)
      end
    end

    it 'can be opted out of, which writes no dumps' do
      expect(ReleaseScan::Gitleaks::StringDumps).not_to receive(:new)
      with_binary(packed) do |path, root|
        code = with_environment('PATH' => '') { run_cli('--output', root.join('out').to_s, path.to_s, '--no-gitleaks') }
        expect(code).to eq(1)
      end
    end

    it 'adds its findings by default' do
      skip 'gitleaks is not installed' unless ReleaseScan::Gitleaks.available?

      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp)
        archive = root.join('App.ipa')
        write_zip(archive, 'res/node_modules/x/index.js' => "one\nid=#{aws_key}\n")
        expect(run_default_cli('--output', root.join('out').to_s, archive.to_s)).to eq(1)
        rules = rules_of(JSON.parse(root.join('out', 'report.json').read)['findings'])
        expect(rules).to include('aws-access-key-id', a_string_starting_with('gitleaks:'))
      end
    end
  end
end
