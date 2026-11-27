# frozen_string_literal: true

require 'json'

require_relative 'models'

module ReleaseScan
  module Report
    SEVERITY_ORDER = { 'critical' => 0, 'high' => 1, 'info' => 2 }.freeze
    ACTIONABLE = %w[critical high].freeze

    module_function

    def render(result, scanned_at)
      actionable = result.findings.select { ACTIONABLE.include?(_1.severity) }
      lines = [
        '# Release binary secret scan',
        '',
        "`#{result.label}`, scanned at #{scanned_at}: #{result.status}.",
        'Values are redacted.',
        'Digests are the first 16 hex chars of SHA-256.',
        '',
      ]
      lines.push('## Error', '', result.reason, '') unless result.reason.empty?

      lines.push('## Findings', '')
      actionable.sort_by { [SEVERITY_ORDER.fetch(_1.severity), _1.rule] }.each do |finding|
        digest_text = finding.digest.empty? ? '' : " digest `#{finding.digest}`"
        lines << "- #{finding.severity} `#{finding.rule}` at `#{finding.location}` " \
                 "offset #{finding.offset}: `#{finding.summary}`#{digest_text}"
        lines << "  #{finding.detail}"
      end
      lines << 'No critical or high findings.' if actionable.empty?
      lines << ''

      lines.push('## Info counts', '')
      info = result.findings.select { _1.severity == 'info' }.map(&:rule).tally
      lines.concat(info.empty? ? ['None.'] : info.sort.map { |rule, count| "- `#{rule}`: #{count}" })
      lines << ''

      lines.push('## Coverage notes', '')
      lines.concat(result.notes.empty? ? ['None.'] : result.notes.map { "- #{_1}" })
      lines << ''
      lines.join("\n")
    end

    def findings_json(result)
      payload = {
        'label' => result.label,
        'status' => result.status,
        'reason' => result.reason,
        'notes' => result.notes,
        'findings' => result.findings.map(&:to_h)
      }
      "#{JSON.pretty_generate(payload)}\n"
    end
  end
end
