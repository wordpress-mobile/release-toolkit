# frozen_string_literal: true

require 'digest'
require 'pathname'

require_relative 'extract'
require_relative 'models'

module ReleaseScan
  module Scan
    CREDENTIAL_FIELD = 'api[_-]?key|client[_-]?secret|password'
    BASIC_AUTH_TOKEN = %r{/token:([A-Za-z0-9]{20,80})}
    URL_PATTERN = %r{\Ahttps?://}i
    B64 = %r{(?:[A-Za-z0-9+/]{40,}={0,2})}
    PEM_HEADER = /-----BEGIN [A-Z ]*PRIVATE KEY-----/
    PEM_BLOCK = %r{-----BEGIN [A-Z ]*PRIVATE KEY-----(?:[A-Za-z0-9+/=\r\n]|\\[rn]){40,}}
    GOOGLE_KEY = /\b(AIza[0-9A-Za-z_-]{35})\b/
    ASSIGNED = /(?:#{CREDENTIAL_FIELD})\\?["']?\s*[:=]\s*\\?["']([A-Za-z0-9]{20,80})\\?["']/i
    PLIST_PAIR = %r{<key>[^<]*(?:#{CREDENTIAL_FIELD})</key>\s*<string>\s*([A-Za-z0-9]{20,80})\s*</string>}i
    SHAPED_MINIMUM = 20

    TokenRule = Struct.new(:id, :severity, :pattern, :entropy, :detail)
    TOKEN_END = /(?:[`'"\s;]|\\[nr]|$)/

    # Ported from the gitleaks default config, keeping its rule ids and entropy floors.
    TOKEN_RULES = [
      TokenRule.new('aws-access-key-id', 'critical', /\b((?:A3T[A-Z0-9]|AKIA|ASIA|ABIA|ACCA)[A-Z2-7]{16})\b/, nil, 'AWS access key id.'),
      TokenRule.new('github-pat', 'high', /(ghp_[0-9a-zA-Z]{36})/, 3, 'GitHub personal access token.'),
      TokenRule.new('github-fine-grained-pat', 'high', /(github_pat_\w{82})/, 3, 'GitHub fine-grained token.'),
      TokenRule.new('github-oauth', 'high', /(gho_[0-9a-zA-Z]{36})/, 3, 'GitHub OAuth token.'),
      TokenRule.new('github-app-token', 'high', /((?:ghu|ghs)_[0-9a-zA-Z]{36})/, 3, 'GitHub app token.'),
      TokenRule.new('github-refresh-token', 'high', /(ghr_[0-9a-zA-Z]{36})/, 3, 'GitHub refresh token.'),
      TokenRule.new('npm-access-token', 'high', /\b(npm_[a-z0-9]{36})#{TOKEN_END}/i, 2, 'npm access token.'),
      TokenRule.new('sendgrid-api-token', 'high', /\b(SG\.(?i:[a-z0-9=_\-.]{66}))#{TOKEN_END}/, 2, 'SendGrid API token.'),
      TokenRule.new('stripe-access-token', 'critical', /\b((?:sk|rk)_(?:test|live|prod)_[a-zA-Z0-9]{10,99})#{TOKEN_END}/, 2, 'Stripe key.'),
      TokenRule.new('slack-bot-token', 'critical', /(xoxb-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*)/, 3, 'Slack bot token.'),
      TokenRule.new('slack-user-token', 'critical', /(xox[pe](?:-[0-9]{10,13}){3}-[a-zA-Z0-9-]{28,34})/, 2, 'Slack user token.'),
      TokenRule.new('slack-app-token', 'high', /(xapp-\d-[A-Z0-9]+-\d+-[a-z0-9]+)/i, 2, 'Slack app token.'),
      TokenRule.new('slack-config-access-token', 'high', /(xoxe.xox[bp]-\d-[A-Z0-9]{163,166})/i, 2, 'Slack configuration token.'),
      TokenRule.new('slack-config-refresh-token', 'high', /(xoxe-\d-[A-Z0-9]{146})/i, 2, 'Slack configuration refresh token.'),
      TokenRule.new('slack-legacy-bot-token', 'high', /(xoxb-[0-9]{8,14}-[a-zA-Z0-9]{18,26})/, 2, 'Slack legacy bot token.'),
      TokenRule.new('slack-legacy-token', 'high', /(xox[os]-\d+-\d+-\d+-[a-fA-F\d]+)/, 2, 'Slack legacy token.'),
      TokenRule.new('slack-legacy-workspace-token', 'high', /(xox[ar]-(?:\d-)?[0-9a-zA-Z]{8,48})/, 2, 'Slack legacy workspace token.'),
      TokenRule.new('slack-webhook-url', 'high', %r{((?:https?://)?hooks\.slack\.com/(?:services|workflows|triggers)/[A-Za-z0-9+/]{43,56})}, nil, 'Slack webhook URL.'),
    ].freeze

    MINIMUM_STRING = 8

    SKIP_SUFFIXES = %w[
      .png .jpg .jpeg .gif .webp .pdf .car .mp3 .m4a .wav .aac .ttf .otf
      .woff .woff2 .ico .svg .nib .storyboardc .metallib .mom .omo .mlmodel
      .pcm .caf .mov .mp4 .atlas .sks
    ].freeze
    OPAQUE_SUFFIXES = %w[.gz .tgz .xz .bz2 .zst .7z .rar .dmg .pkg .deb .msi .appimage .exe].freeze
    OUTER_BYTES_NOTE = 'may be compressed, only its outer bytes were read'
    MAX_FILE_BYTES = 250 * 1024 * 1024
    MAX_TEXT_BYTES = 2 * 1024 * 1024
    TEXT_PROBE_BYTES = 8192

    module_function

    def redact(value)
      return '•' * value.length if value.length <= 8

      "#{value[0, 4]}…#{value[-2, 2]}"
    end

    def digest(value)
      Digest::SHA256.hexdigest(value)[0, 16]
    end

    def shannon(value)
      counts = value.chars.tally
      length = value.length.to_f
      -counts.values.sum do |count|
        probability = count / length
        probability * Math.log2(probability)
      end
    end

    def token_shaped?(value)
      return false unless /\A[A-Za-z0-9]{#{SHAPED_MINIMUM},80}\z/.match?(value)
      return false if /\A[0-9a-fA-F]+\z/.match?(value)
      return false unless value.match?(/\d/)

      value.match?(/[A-Za-z]/) && shannon(value) >= 3.0
    end

    def read_bytes(path)
      Pathname.new(path).binread
    end

    def string_tables(data)
      { 1 => ascii_strings(data), 2 => utf16le_strings(data) }
    end

    def ascii_strings(data, minimum = MINIMUM_STRING)
      pattern = /[\x20-\x7E]{#{minimum},}/n
      found = []
      data.scan(pattern) do
        match = Regexp.last_match
        found << [match.begin(0), match[0].force_encoding(Encoding::UTF_8)]
      end
      found
    end

    def utf16le_strings(data, minimum = MINIMUM_STRING)
      pattern = /(?:[\x20-\x7E]\x00){#{minimum},}/n
      found = []
      data.scan(pattern) do
        match = Regexp.last_match
        found << [match.begin(0), match[0].delete("\0").force_encoding(Encoding::UTF_8)]
      end
      found
    end

    def scan_text(text, location)
      findings = []
      scan_patterns(text, location, 0, findings)
      scan_multiline(text, location, findings)
      dedupe(findings)
    end

    def scan_string_table(items, location, width)
      items = items.sort_by(&:first)
      findings = []
      items.each { |offset, text| scan_patterns(text, location, offset, findings) }
      beside_url(items, width, location, findings)
      dedupe(findings)
    end

    def scan_tree(root, location_prefix, dumps)
      root = Pathname.new(root)
      findings = []
      failures = []
      notes = []
      scanned = 0

      Extract.files_under(root).each do |relative|
        next if Extract.debug_symbols?(relative)

        path = root.join(relative)
        begin
          kind = classify(path)
          next if kind == :skip

          findings.concat(scan_member(path, kind, "#{location_prefix}:#{relative}", relative, dumps))
          scanned += 1
          notes << "#{relative}: #{OUTER_BYTES_NOTE}" if opaque?(path)
        rescue StandardError => e
          failures << "#{relative}: #{e.message}"
        end
      end
      [dedupe(findings), scanned, failures, notes]
    end

    def scan_member(path, kind, location, relative, dumps)
      return scan_binary(read_bytes(path), location, relative, dumps) unless kind == :text

      text = read_bytes(path).force_encoding(Encoding::UTF_8).scrub
      dumps&.add_text(relative, text)
      scan_text(text, location)
    end
    private_class_method :scan_member

    def scan_binary(data, location, relative, dumps)
      grouped = string_tables(data)
      dumps&.add_table(relative, grouped.values.flatten(1))
      findings = grouped.flat_map { |width, table| scan_string_table(table, location, width) }
      scan_multiline(data, location, findings)
      dedupe(findings)
    end
    private_class_method :scan_binary

    def opaque?(path)
      OPAQUE_SUFFIXES.include?(Pathname.new(path).extname.downcase)
    end

    def scan_file(path, location, dumps = nil)
      path = Pathname.new(path)
      raise "#{path} is empty" if path.empty?
      raise "#{path} is #{path.size} bytes, over the #{MAX_FILE_BYTES} byte cap" if path.size > MAX_FILE_BYTES

      scan_binary(read_bytes(path), location, path.basename.to_s, dumps)
    end

    def scan_patterns(text, location, offset, findings)
      matches(text, BASIC_AUTH_TOKEN).each do |match|
        value = match[1]
        next unless token_shaped?(value)

        add_secret(findings, 'basic-auth-token', 'critical', location, offset, value,
                   'Basic-auth token material.')
      end

      TOKEN_RULES.each do |rule|
        matches(text, rule.pattern).each do |match|
          next if rule.entropy && shannon(match[1]) < rule.entropy

          add_secret(findings, rule.id, rule.severity, location, offset, match[1], rule.detail)
        end
      end
      matches(text, GOOGLE_KEY).each do |match|
        add_secret(findings, 'google-api-key', 'info', location, offset, match[1],
                   'Google API key. Usually expected inside a client.')
      end
      matches(text, ASSIGNED).each do |match|
        next unless token_shaped?(match[1])

        add_secret(findings, 'assigned-secret', 'high', location, offset, match[1],
                   'Value assigned beside a credential field name.')
      end
      scan_basic_blobs(text, location, offset, findings)
    end
    private_class_method :scan_patterns

    # Newlines end a string-table entry, so anything spanning lines has to match the whole content.
    def scan_multiline(content, location, findings)
      blocks = matches(content, PEM_BLOCK)
      blocks.each do |match|
        add_secret(findings, 'private-key', 'critical', location, match.byteoffset(0).first,
                   utf8(match[0]), 'PEM private key block.')
      end
      matches(content, PEM_HEADER).each do |match|
        next if blocks.any? { match.begin(0) >= _1.begin(0) && match.begin(0) < _1.end(0) }

        add_public(findings, 'pem-header-literal', 'info', location, match.byteoffset(0).first, utf8(match[0]),
                   'PEM header constant with no key body.')
      end
      matches(content, PLIST_PAIR).each do |match|
        next unless token_shaped?(match[1])

        add_secret(findings, 'assigned-secret', 'high', location, match.byteoffset(0).first,
                   utf8(match[1]), 'Value assigned beside a credential field name.')
      end
    end
    private_class_method :scan_multiline

    def utf8(value)
      value.dup.force_encoding(Encoding::UTF_8)
    end
    private_class_method :utf8

    def scan_basic_blobs(text, location, offset, findings)
      matches(text, B64).each do |match|
        raw = match[0]
        padded = raw + ('=' * ((4 - (raw.length % 4)) % 4))
        begin
          decoded = padded.unpack1('m0').force_encoding(Encoding::UTF_8).scrub
        rescue ArgumentError
          next
        end
        embedded = BASIC_AUTH_TOKEN.match(decoded)
        next unless embedded && token_shaped?(embedded[1])

        add_secret(findings, 'basic-auth-token-b64', 'critical', location, offset, embedded[1],
                   'Base64 blob decodes to basic-auth token material.')
      end
    end
    private_class_method :scan_basic_blobs

    def beside_url(items, width, location, findings)
      items.each_cons(2) do |(left_offset, left), (right_offset, right)|
        next unless adjacent?(left_offset, left, right_offset, width)

        if token_shaped?(left) && URL_PATTERN.match?(right)
          add_secret(findings, 'shaped-value-beside-url', 'critical', location, left_offset, left,
                     'Shaped value packed beside a URL.')
        elsif token_shaped?(right) && URL_PATTERN.match?(left)
          add_secret(findings, 'shaped-value-beside-url', 'critical', location, right_offset, right,
                     'Shaped value packed beside a URL.')
        end
      end
    end
    private_class_method :beside_url

    def adjacent?(previous_offset, previous_text, offset, width)
      gap = offset - (previous_offset + (previous_text.bytesize * width))
      gap.between?(1, 16)
    end
    private_class_method :adjacent?

    def add_public(findings, rule, severity, location, offset, text, detail)
      findings << Finding.new(
        rule: rule,
        severity: severity,
        location: location,
        offset: offset,
        summary: text,
        digest: '',
        detail: detail
      )
    end
    private_class_method :add_public

    def add_secret(findings, rule, severity, location, offset, value, detail)
      findings << Finding.new(
        rule: rule,
        severity: severity,
        location: location,
        offset: offset,
        summary: redact(value),
        digest: digest(value),
        detail: detail
      )
    end
    private_class_method :add_secret

    def dedupe(findings)
      findings.uniq { [_1.rule, _1.location, _1.offset, _1.digest, _1.summary] }
    end
    private_class_method :dedupe

    def classify(path)
      return :skip if path.symlink? || !path.file?
      return :skip if SKIP_SUFFIXES.include?(path.extname.downcase)

      size = path.size
      return :skip if size.zero?
      raise "#{path.basename} is #{size} bytes, over the #{MAX_FILE_BYTES} byte cap" if size > MAX_FILE_BYTES

      head = path.open('rb') { _1.read(TEXT_PROBE_BYTES) }
      return :bytes if head.start_with?('bplist') || head.include?("\0") || size > MAX_TEXT_BYTES

      :text
    end
    private_class_method :classify

    def matches(text, pattern)
      text.to_enum(:scan, pattern).map { Regexp.last_match }
    end
    private_class_method :matches
  end
end
