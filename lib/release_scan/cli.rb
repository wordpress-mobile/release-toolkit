# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'pathname'
require 'time'
require 'tmpdir'

require_relative 'extract'
require_relative 'gitleaks'
require_relative 'models'
require_relative 'report'
require_relative 'scan'

module ReleaseScan
  module CLI
    DEFAULT_OUTPUT = 'release-scan'

    module_function

    def run(argv)
      arguments = argv.dup
      options = { output: Pathname.new(DEFAULT_OUTPUT), gitleaks: true, label: '' }
      parser = option_parser(options)
      parser.parse!(arguments)
      path = arguments.shift
      raise OptionParser::MissingArgument, 'PATH' unless path
      raise OptionParser::InvalidOption, arguments.join(' ') if arguments.any?

      scan(Pathname.new(path), options)
    rescue OptionParser::ParseError => e
      warn e.message
      warn parser
      2
    rescue StandardError => e
      warn e.message
      2
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.banner = "Usage: release-scan PATH [options]\n\n" \
                        'PATH is an .xcarchive or .app directory, a zip package (.xcarchive.zip, .ipa, .apk, .aab), or a binary.'
        parser.on('--output DIR', "Directory for report.md and report.json. Default: #{DEFAULT_OUTPUT}") { options[:output] = Pathname.new(_1) }
        parser.on('--label TEXT', 'Name for the report. Default: the file name of PATH.') { options[:label] = _1 }
        parser.on('--[no-]gitleaks', 'Also run gitleaks (default). It is an error if it is not installed.') { options[:gitleaks] = _1 }
        parser.on('-h', '--help') do
          puts parser
          exit 0
        end
      end
    end
    private_class_method :option_parser

    def scan(path, options)
      use_gitleaks = options[:gitleaks]
      if use_gitleaks && !Gitleaks.available?
        warn 'gitleaks is not installed'
        return 2
      end

      label = options[:label].empty? ? path.expand_path.basename.to_s : options[:label]
      findings, status, reason, notes = Dir.mktmpdir('release-scan') do |work|
        scan_package(path, label, Pathname.new(work), use_gitleaks)
      end
      result = ScanResult.new(label: label, status: status, reason: reason, findings: findings, notes: notes)
      write_reports(options[:output], result)
      exit_code(result)
    end
    private_class_method :scan

    def scan_package(path, label, work, use_gitleaks)
      findings = []
      errors = []
      notes = []
      extracted = work.join('extracted')
      begin
        dumps = Gitleaks::StringDumps.new(work.join('strings')) if use_gitleaks
        if path.directory? || zip_file?(path)
          unpacked = path.directory? ? Extract.copy_tree(path, extracted) : Extract.safe_extract(path, extracted)
          notes.concat(unpacked)
          findings, scanned, errors, tree_notes = Scan.scan_tree(extracted, label, dumps)
          notes.concat(tree_notes)
          errors << "no binaries in #{path}" if scanned.zero? && errors.empty?
        else
          findings = Scan.scan_file(path, label, dumps)
          notes << Scan::OUTER_BYTES_NOTE if Scan.opaque?(path)
        end
        findings.concat(Gitleaks.run(dumps, label)) if use_gitleaks && dumps.any?
      rescue StandardError => e
        errors << e.message
      ensure
        FileUtils.rm_rf(work.join('strings'))
        FileUtils.rm_rf(extracted)
      end
      status = errors.empty? ? 'scanned' : 'error'
      [findings, status, errors.join('; '), notes]
    end
    private_class_method :scan_package

    def zip_file?(path)
      signature = Pathname.new(path).open('rb') { _1.read(4) }
      ["PK\x03\x04", "PK\x05\x06", "PK\x07\x08"].include?(signature)
    rescue Errno::ENOENT, Errno::EISDIR
      false
    end
    private_class_method :zip_file?

    def write_reports(output, result)
      FileUtils.mkdir_p(output)
      scanned_at = Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')
      report = output.join('report.md')
      report.write(Report.render(result, scanned_at))
      output.join('report.json').write(Report.findings_json(result))
      warn "Wrote #{report}"
    end
    private_class_method :write_reports

    def exit_code(result)
      return 2 if result.status == 'error'

      result.findings.any? { Report::ACTIONABLE.include?(_1.severity) } ? 1 : 0
    end
    private_class_method :exit_code
  end
end
