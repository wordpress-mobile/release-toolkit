# frozen_string_literal: true

require 'spec_helper'
require_relative 'release_scan_helpers'

describe ReleaseScan::Scan do
  include ReleaseScanHelpers

  def table(parts, start = 32)
    offset = start
    parts.map do |part|
      item = [offset, part]
      offset += part.bytesize + 1
      item
    end
  end

  def assigned_digests(text)
    described_class.scan_text(text, 'Config').select { |finding| finding.rule == 'assigned-secret' }.map(&:digest).uniq
  end

  def scan_bytes(bytes)
    Dir.mktmpdir do |tmp|
      path = Pathname.new(tmp).join('App')
      path.binwrite(bytes)
      described_class.scan_file(path, 'App')
    end
  end

  def macho_with_linkedit(linkedit)
    fileoff = 4096
    segment = [0x19, 72].pack('L<L<') + '__LINKEDIT'.ljust(16, "\0") +
              [0x100000000, 4096, fileoff, linkedit.bytesize, 1, 1, 0, 0].pack('Q<Q<Q<Q<L<L<L<L<')
    header = [0xFEEDFACF, 0x0100000C, 0, 2, 1, segment.bytesize, 0, 0].pack('L<L<L<L<L<L<L<L<')
    (header + segment).ljust(fileoff, "\0".b) + linkedit.b
  end

  describe '.token_shaped?' do
    it 'rejects hex and placeholders' do
      expect(described_class.token_shaped?(ReleaseScanHelpers::HEX)).to be false
      expect(described_class.token_shaped?('%{api_key}')).to be false # rubocop:disable Style/FormatStringToken
      expect(described_class.token_shaped?('loggingEncryptionKey')).to be false
      expect(described_class.token_shaped?(ReleaseScanHelpers::TOKEN)).to be true
    end
  end

  describe 'shaped values beside a URL' do
    let(:token) { ReleaseScanHelpers::TOKEN }
    let(:url) { ReleaseScanHelpers::URL }

    it 'finds both orders and the basic-auth form' do
      second = ReleaseScanHelpers::SECOND
      findings = described_class.scan_string_table(table([token, url, second, "user@example.com/token:#{token}"]), 'App', 1)
      expect(rules_of(findings)).to include('shaped-value-beside-url', 'basic-auth-token')
      expect(findings.map(&:digest)).to include(digest(token), digest(second))
    end

    it 'ignores a shaped value beside something else' do
      expect(described_class.scan_string_table([[100, token], [100 + token.length + 1, 'not-a-url']], 'App', 1)).to be_empty
    end

    it 'counts gaps of 1 to 16 bytes as packed' do
      [1, 8, 16].each do |gap|
        findings = described_class.scan_string_table([[100, token], [100 + token.length + gap, url]], 'App', 1)
        expect(findings.first.rule).to eq('shaped-value-beside-url')
        expect(findings.first.digest).to eq(digest(token))
      end
    end

    it 'does not count a gap of 0 or 17 bytes' do
      [0, 17].each do |gap|
        findings = described_class.scan_string_table([[100, token], [100 + token.length + gap, url]], 'App', 1)
        expect(rules_of(findings)).not_to include('shaped-value-beside-url')
        expect(findings.map(&:digest).reject(&:empty?)).to be_empty
      end
    end

    it 'measures UTF-16 literals with a two byte stride' do
      raw = "#{token.encode(Encoding::UTF_16LE).b}\0\0#{url.encode(Encoding::UTF_16LE).b}\0\0"
      findings = described_class.scan_string_table(described_class.utf16le_strings(raw), 'App', 2)
      expect(rules_of(findings)).to include('shaped-value-beside-url')
    end

    it 'finds them through the string tables of a binary' do
      grouped = described_class.string_tables(packed)
      expect(rules_of(described_class.scan_string_table(grouped[1], 'App', 1))).to include('shaped-value-beside-url')
    end
  end

  describe 'basic-auth tokens' do
    it 'finds one inside base64 without exposing it' do
      token = ReleaseScanHelpers::TOKEN
      encoded = ["user@example.com/token:#{token}"].pack('m0')
      finding = described_class.scan_string_table([[0, encoded]], 'App', 1).first
      expect(finding.rule).to eq('basic-auth-token-b64')
      expect(finding.digest).to eq(digest(token))
      expect(finding.summary).not_to include(token)
    end
  end

  describe 'PEM private keys' do
    let(:header) { ReleaseScanHelpers::PEM_HEADER_TEXT }
    let(:body) { ReleaseScanHelpers::PEM_BODY }

    it 'treats a header without a body as info' do
      finding = described_class.scan_text("#{header}\n", 'Crypto.swift').first
      expect(finding.rule).to eq('pem-header-literal')
      expect(finding.severity).to eq('info')
      expect(finding.digest).to be_empty
    end

    it 'treats a block as a critical secret' do
      block = "#{header}#{'Ab9' * 20}"
      findings = described_class.scan_text(block, 'block.txt')
      expect(rules_of(findings)).to eq(['private-key'])
      expect(findings.first.severity).to eq('critical')
      expect(findings.first.summary).not_to include(block)
    end

    it 'finds a multi-line block in a binary at its real offset' do
      findings = scan_bytes("\xC1\0\0\0".b + "#{header}\n#{body}\n#{body}\n\0")
      expect(rules_of(findings)).to eq(['private-key'])
      expect(findings.first.severity).to eq('critical')
      expect(findings.first.offset).to eq(4)
      expect(findings.first.summary).not_to include(body)
      expect { JSON.generate(findings.first.to_h) }.not_to raise_error
    end

    it 'finds a block with escaped newlines in JSON' do
      findings = described_class.scan_text(%({"private_key":"#{header}\\n#{body}\\n"}), 'service.json')
      expect(rules_of(findings)).to eq(['private-key'])
      expect(findings.first.severity).to eq('critical')
    end

    it 'keeps a bare header in a binary at info' do
      findings = scan_bytes("\0\0#{header}\0\0")
      expect(rules_of(findings)).to eq(['pem-header-literal'])
      expect(findings.first.digest).to be_empty
    end
  end

  describe 'assigned secrets' do
    let(:token) { ReleaseScanHelpers::TOKEN }

    it 'reports an assignment as high' do
      finding = described_class.scan_text("api_key = \"#{token}\"\n", 'Config.swift').first
      expect(finding.rule).to eq('assigned-secret')
      expect(finding.severity).to eq('high')
      expect(finding.digest).to eq(digest(token))
    end

    it 'matches the forms config really uses' do
      [
        %({"api_key":"#{token}"}),
        %({"client_secret" : "#{token}"}),
        %({\\"password\\":\\"#{token}\\"}),
        %(x_api_key = "#{token}"),
        %(MY_CLIENT_SECRET='#{token}'),
        %(let apiKey = "#{token}"),
        "<key>client_secret</key>\n  <string>#{token}</string>",
        "<key>MY_API_KEY</key><string>#{token}</string>",
      ].each { |text| expect(assigned_digests(text)).to eq([digest(token)]), text }
    end

    it 'ignores other fields and unshaped values' do
      [
        %(password_hint = "#{token}"),
        %(api_key = "placeholder"),
        %(api_key = "#{ReleaseScanHelpers::HEX}"),
        "<key>title</key><string>#{token}</string>",
      ].each { |text| expect(assigned_digests(text)).to be_empty, text }
    end

    it 'matches an XML plist pair inside a binary' do
      findings = scan_bytes("\0\0<key>api_key</key>\n<string>#{token}</string>\n\0\0")
      expect(rules_of(findings)).to include('assigned-secret')
      expect(findings.map(&:digest).uniq).to eq([digest(token)])
    end
  end

  describe 'vendor tokens' do
    it 'finds every sample in text without exposing it' do
      vendor_samples.each do |rule, sample|
        findings = described_class.scan_text("value=\"#{sample}\"\n", 'config')
        expect(rules_of(findings)).to include(rule)
        expect(findings.map(&:summary).join).not_to include(sample)
      end
    end

    it 'finds every sample in a binary' do
      rules = rules_of(scan_bytes("\0\0#{vendor_samples.values.join("\0")}\0\0"))
      expect(rules).to include(*vendor_samples.keys)
    end

    it 'ignores low-entropy lookalikes' do
      {
        'github-pat' => ['gh', 'p_', 'a' * 36].join,
        'stripe-access-token' => ['s', 'k_live_', 'a' * 30].join
      }.each do |rule, sample|
        expect(rules_of(described_class.scan_text("value=\"#{sample}\"\n", 'config'))).not_to include(rule)
      end
    end

    it 'assigns the documented severities' do
      severities = described_class::TOKEN_RULES.to_h { |rule| [rule.id, rule.severity] }
      expect(severities).to include(
        'slack-bot-token' => 'critical', 'stripe-access-token' => 'critical',
        'github-pat' => 'high', 'npm-access-token' => 'high'
      )
    end

    it 'finds an AWS access key id without exposing it' do
      key = ReleaseScanHelpers::AWS_KEY
      finding = described_class.scan_text("id=#{key}", 'config').first
      expect(finding.rule).to eq('aws-access-key-id')
      expect(finding.severity).to eq('critical')
      expect(finding.digest).to eq(digest(key))
      expect(finding.summary).not_to include(key)
    end
  end

  describe 'string extraction' do
    it 'reads the __LINKEDIT segment of a Mach-O' do
      bytes = macho_with_linkedit("\0\0#{ReleaseScanHelpers::TOKEN}\0#{ReleaseScanHelpers::URL}\0\0")
      expect(rules_of(scan_bytes(bytes))).to include('shaped-value-beside-url')
    end

    it 'reads strings with no terminator and splits on tab' do
      strings = described_class.ascii_strings("\x01firstvalue\x02secondvalue\tthirdvalue\xC1".b).map(&:last)
      expect(strings).to eq(%w[firstvalue secondvalue thirdvalue])
    end

    it 'keeps the offsets of UTF-16 regions' do
      raw = "\0\0".b + 'exampleutf'.encode(Encoding::UTF_16LE).b + "\0\0".b
      expect(described_class.utf16le_strings(raw)).to eq([[2, 'exampleutf']])
    end

    it 'raises for a path it cannot read' do
      Dir.mktmpdir do |tmp|
        expect { described_class.read_bytes(Pathname.new(tmp)) }.to raise_error(SystemCallError)
      end
    end
  end

  describe '.scan_tree' do
    it 'does not read debug symbols' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp)
        dwarf = root.join('dSYMs', 'App.app.dSYM', 'Contents', 'Resources', 'DWARF')
        dwarf.mkpath
        dwarf.join('App').binwrite(packed)
        app = root.join('Payload', 'App.app')
        app.mkpath
        app.join('App').binwrite("\0" * (120 * 1024))
        findings, = described_class.scan_tree(root, 'archive', nil)
        expect(findings).to be_empty
      end
    end

    it 'records an oversize member as a failure, not a silent skip' do
      Dir.mktmpdir do |tmp|
        root = Pathname.new(tmp).join('tree')
        root.mkpath
        root.join('App').binwrite(binary("hello from the app\0"))
        File.open(root.join('Huge'), 'wb') { |file| file.truncate(described_class::MAX_FILE_BYTES + 1) }
        _, scanned, failures = described_class.scan_tree(root, 'archive', nil)
        expect(scanned).to eq(1)
        expect(failures.first).to include('Huge')
      end
    end
  end
end
