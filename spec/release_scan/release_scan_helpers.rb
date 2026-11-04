# frozen_string_literal: true

require 'json'
require 'pathname'
require 'tmpdir'
require 'zip'
require 'release_scan'

module ReleaseScanHelpers
  TOKEN = 'ZdTestTokenNotReal0123456789abcdEF'
  SECOND = 'Ab9SecondSecretValueNotRealxx12'
  URL = 'https://example.com'
  HEX = '0123456789abcdef0123456789abcdef01234567'

  # Fixtures that look like real credentials are split so that secret scanners do not flag this file.
  AWS_KEY = %w[AKIA 7Z3QPLM2VXBC4N6R].join.freeze
  PEM_HEADER_TEXT = ['-----BEGIN ', 'PRIVATE KEY-----'].join.freeze
  PEM_BODY = 'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7' * 2
  VENDOR_BODY = 'a7Kq2Xw9Lm3Zp8Rt5Vb1Nc6Jh4Gd0Sf3Yu7Ei2OaT6'
  VENDOR_DIGITS = '4827361950'

  def digest(value)
    ReleaseScan::Scan.digest(value)
  end

  def binary(value)
    ("\0" * 32) + value + ("\0" * (120 * 1024))
  end

  def packed(value = TOKEN)
    binary("#{value}\0#{URL}\0")
  end

  def rules_of(findings)
    findings.map { |finding| finding.respond_to?(:rule) ? finding.rule : finding['rule'] }
  end

  def write_zip(path, entries)
    Zip::File.open(path.to_s, create: true) do |archive|
      entries.each do |name, contents|
        archive.get_output_stream(name) { |stream| stream.write(contents) }
      end
    end
  end

  def zip_bytes(entries)
    Dir.mktmpdir do |tmp|
      path = Pathname.new(tmp).join('inner.zip')
      write_zip(path, entries)
      path.binread
    end
  end

  def with_environment(values)
    original = values.to_h { |key, _| [key, ENV.fetch(key, nil)] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  def silently
    streams = [$stdout, $stderr]
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout, $stderr = streams
  end

  # Runs the CLI without gitleaks unless the arguments mention it, so only the specs about gitleaks need the binary.
  def run_cli(*arguments)
    arguments += ['--no-gitleaks'] unless arguments.any? { |argument| argument.include?('gitleaks') }
    silently { ReleaseScan::CLI.run(arguments) }
  end

  def run_default_cli(*arguments)
    silently { ReleaseScan::CLI.run(arguments) }
  end

  def scan_members(entries)
    Dir.mktmpdir do |tmp|
      root = Pathname.new(tmp)
      archive = root.join('App.ipa')
      write_zip(archive, entries)
      code = run_cli('--output', root.join('out').to_s, archive.to_s)
      report = JSON.parse(root.join('out', 'report.json').read)
      [code, report['findings'], report]
    end
  end

  def build_xcarchive(root)
    archive = root.join('App.xcarchive')
    app = archive.join('Products', 'Applications', 'App.app')
    app.mkpath
    app.join('App').binwrite(packed)
    app.join('Bundle.zip').binwrite(zip_bytes('inner/Lib' => packed(SECOND)))
    File.symlink('App', app.join('Link'))
    dwarf = archive.join('dSYMs', 'App.app.dSYM', 'Contents', 'Resources', 'DWARF')
    dwarf.mkpath
    dwarf.join('App').binwrite(binary("#{HEX}Zz\0#{URL}\0"))
    archive
  end

  def snapshot(directory)
    Dir.glob('**/*', File::FNM_DOTMATCH, base: directory.to_s).sort.to_h do |name|
      path = File.join(directory.to_s, name)
      contents = if File.symlink?(path)
                   File.readlink(path)
                 else
                   File.file?(path) ? File.binread(path) : :directory
                 end
      [name, contents]
    end
  end

  def vendor_samples
    body = VENDOR_BODY[0, 36]
    {
      'github-pat' => ['gh', 'p_', body].join,
      'github-oauth' => ['gh', 'o_', body].join,
      'github-app-token' => ['gh', 's_', body].join,
      'github-refresh-token' => ['gh', 'r_', body].join,
      'github-fine-grained-pat' => ['github', '_pat_', (VENDOR_BODY * 2)[0, 82]].join,
      'npm-access-token' => ['np', 'm_', body.downcase].join,
      'sendgrid-api-token' => ['S', 'G.', (VENDOR_BODY * 2)[0, 66]].join,
      'stripe-access-token' => ['s', 'k_live_', VENDOR_BODY].join,
      'slack-bot-token' => ['xo', 'xb-', VENDOR_DIGITS, '-', VENDOR_DIGITS, '-', VENDOR_BODY[0, 24]].join,
      'slack-user-token' => ['xo', 'xp-', ([VENDOR_DIGITS] * 3).join('-'), '-', VENDOR_BODY[0, 32]].join,
      'slack-app-token' => ['xa', 'pp-1-A1B2C3D4E5-', VENDOR_DIGITS, '-', VENDOR_BODY.downcase].join,
      'slack-webhook-url' => ['https://hooks.', 'slack.com/services/', "#{VENDOR_BODY}A"[0, 44]].join,
      'slack-legacy-bot-token' => ['xo', 'xb-', VENDOR_DIGITS, '-', VENDOR_BODY[0, 22]].join,
      'slack-legacy-token' => ['xo', 'xs-1-2-3-abcdef0123'].join,
      'slack-legacy-workspace-token' => ['xo', 'xa-', VENDOR_BODY[0, 32]].join,
      'slack-config-access-token' => ['xo', 'xe.xoxb-1-', (VENDOR_BODY * 5)[0, 165]].join,
      'slack-config-refresh-token' => ['xo', 'xe-1-', (VENDOR_BODY * 4)[0, 146]].join
    }
  end
end
