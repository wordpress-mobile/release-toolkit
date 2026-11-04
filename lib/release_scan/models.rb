# frozen_string_literal: true

module ReleaseScan
  Finding = Struct.new(
    :rule,
    :severity,
    :location,
    :offset,
    :summary,
    :digest,
    :detail,
    keyword_init: true
  )

  ScanResult = Struct.new(:label, :status, :reason, :findings, :notes, keyword_init: true)
end
