# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open3'
require 'pathname'
require 'tmpdir'

require_relative 'models'

module ReleaseScan
  module Gitleaks
    # Numbered names keep gitleaks' default path allowlist (`node_modules`, lockfiles) from hiding a member.
    class StringDumps
      Entry = Struct.new(:member, :offsets)

      attr_reader :directory

      def initialize(directory)
        @directory = Pathname.new(directory)
        FileUtils.mkdir_p(@directory, mode: 0o700)
        @entries = {}
      end

      def add_table(member, table)
        write(member, table.map(&:last).join("\n"), table.map(&:first))
      end

      def add_text(member, text)
        offset = 0
        offsets = text.each_line.map do |line|
          start = offset
          offset += line.bytesize
          start
        end
        write(member, text, offsets)
      end

      def any?
        @entries.any?
      end

      def locate(file, line)
        entry = @entries[File.basename(file)]
        return [file, line] unless entry

        [entry.member, entry.offsets.fetch(line - 1, 0)]
      end

      private

      def write(member, content, offsets)
        return if content.empty?

        name = format('%06d.txt', @entries.length + 1)
        File.write(@directory.join(name), content, perm: 0o600)
        @entries[name] = Entry.new(member, offsets)
      end
    end

    module_function

    def severity(rule_id)
      rule = rule_id.downcase
      return if rule.include?('generic')
      return 'critical' if %w[aws-access slack-bot slack-user stripe-access].any? { rule.include?(_1) }
      return 'high' if %w[github-pat sendgrid npm-access].any? { rule.include?(_1) }
      return 'info' if %w[private-key google gcp firebase sentry jwt].any? { rule.include?(_1) }

      'high'
    end

    def available?
      ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).any? do |directory|
        File.executable?(File.join(directory, 'gitleaks'))
      end
    end

    def run(dumps, label)
      raise 'gitleaks is not installed' unless available?

      payload = nil
      Dir.mktmpdir do |directory|
        report = Pathname.new(directory).join('report.json')
        ignore = Pathname.new(directory).join('ignore')
        ignore.mkdir
        arguments = [
          'gitleaks', 'detect', '--no-git', '--no-banner', '--redact',
          '--ignore-gitleaks-allow', '--exit-code', '0', '--max-target-megabytes', '512',
          '--gitleaks-ignore-path', ignore.to_s, '-s', dumps.directory.to_s, '-f', 'json', '-r', report.to_s,
        ]
        stdout, stderr, status = Open3.capture3(
          { 'GITLEAKS_CONFIG' => nil, 'GITLEAKS_CONFIG_TOML' => nil },
          *arguments
        )
        raise error_message(stderr, stdout) unless status.success?
        raise error_message(stderr, stdout) unless report.exist?

        begin
          report_text = report.read
          payload = JSON.parse(report_text.empty? ? '[]' : report_text)
        rescue JSON::ParserError
          raise 'gitleaks wrote a report that is not JSON'
        end
      end
      raise 'gitleaks report is not a list' unless payload.is_a?(Array)

      findings_from(payload, label, dumps)
    end

    def findings_from(payload, label, dumps)
      findings = []
      suppressed = 0
      payload.each do |item|
        raise 'gitleaks report entry is not an object' unless item.is_a?(Hash)

        rule = item['RuleID'] || 'gitleaks'
        level = severity(rule.to_s)
        if level.nil? || level == 'info'
          suppressed += 1
          next
        end
        member, offset = dumps.locate(item['File'].to_s, (item['StartLine'] || 1).to_i)
        findings << Finding.new(
          rule: "gitleaks:#{rule}",
          severity: level,
          location: "#{label}:#{member}",
          offset: offset,
          summary: 'redacted-by-gitleaks',
          digest: '',
          detail: item['Description'] || rule
        )
      end
      if suppressed.positive?
        findings << Finding.new(
          rule: 'gitleaks-suppressed',
          severity: 'info',
          location: label,
          offset: 0,
          summary: suppressed.to_s,
          digest: '',
          detail: 'Generic, PEM-header, Google, Firebase, Sentry, and JWT gitleaks hits are counted here and not listed.'
        )
      end
      findings
    end
    private_class_method :findings_from

    def error_message(stderr, stdout)
      detail = [stderr, stdout].find { !_1.empty? } || 'gitleaks failed'
      first = detail.strip.lines.first&.strip
      (first.nil? || first.empty? ? 'gitleaks failed' : first)[0, 200]
    end
    private_class_method :error_message
  end
end
