# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'zip'

module ReleaseScan
  module Extract
    MAX_TOTAL_BYTES = 8 * 1024 * 1024 * 1024
    MAX_ENTRIES = 200_000
    MAX_DEPTH = 3
    ZIP_SIGNATURE = "PK\x03\x04".b

    class LimitExceeded < StandardError; end

    class Budget
      def initialize(max_bytes: MAX_TOTAL_BYTES, max_entries: MAX_ENTRIES)
        @bytes = max_bytes
        @entries = max_entries
      end

      attr_reader :bytes

      def spend_entry
        @entries -= 1
        raise LimitExceeded, 'archive has too many entries' if @entries.negative?
      end

      def spend_bytes(count)
        @bytes -= count
        raise LimitExceeded, 'archive expands past the size limit' if @bytes.negative?
      end
    end

    module_function

    def safe_extract(archive, destination, budget: Budget.new, depth: 0)
      extract_members(archive, destination, budget)
      extract_nested(destination, budget, depth)
    end

    # Nested zips are unpacked and deleted, so this must never run on the build output itself.
    def copy_tree(source, destination, budget: Budget.new)
      source = Pathname.new(source)
      destination = Pathname.new(destination)
      FileUtils.mkdir_p(destination)
      files_under(source).each do |relative|
        next if debug_symbols?(relative)

        path = source.join(relative)
        next if path.symlink? || !path.file?

        budget.spend_entry
        budget.spend_bytes(path.size)
        target = destination.join(relative)
        FileUtils.mkdir_p(target.dirname)
        FileUtils.cp(path, target)
      end
      extract_nested(destination, budget, 0)
    end

    def debug_symbols?(relative_path)
      Pathname.new(relative_path).each_filename.any? { _1 == 'dSYMs' || _1.end_with?('.dSYM') }
    end

    def extract_members(archive, destination, budget)
      archive = Pathname.new(archive)
      destination = Pathname.new(destination)
      FileUtils.mkdir_p(destination)
      root = destination.expand_path.to_s

      Zip::File.open(archive) do |bundle|
        bundle.each do |entry|
          budget.spend_entry
          target = member_target(destination, entry.name)
          unless target.to_s == root || target.to_s.start_with?("#{root}/")
            raise ArgumentError, "archive member escapes destination: #{entry.name}"
          end

          if entry.directory? || entry.name.end_with?('/')
            FileUtils.mkdir_p(target)
            next
          end

          FileUtils.mkdir_p(target.dirname)
          entry.get_input_stream do |source|
            unused_path(target).open('wb') do |output|
              budget.spend_bytes(IO.copy_stream(source, output, budget.bytes + 1))
            end
          end
        end
      end
    end
    private_class_method :extract_members

    def extract_nested(destination, budget, depth)
      destination = Pathname.new(destination)
      notes = []
      files_under(destination).each do |relative|
        next if debug_symbols?(relative)

        path = destination.join(relative)
        next unless path.file? && !path.symlink? && zip_signature?(path)

        if depth >= MAX_DEPTH
          notes << "#{relative}: zip nested deeper than #{MAX_DEPTH} levels, read as raw bytes"
          next
        end

        nested = Pathname.new("#{path}!")
        begin
          inner = safe_extract(path, nested, budget: budget, depth: depth + 1)
          notes.concat(inner.map { "#{relative}!/#{_1}" })
          path.delete
        rescue Zip::Error => e
          FileUtils.rm_rf(nested)
          notes << "#{relative}: could not open as a zip (#{e.message}), read as raw bytes"
        end
      end
      notes
    end
    private_class_method :extract_nested

    def files_under(root)
      Dir.glob('**/*', File::FNM_DOTMATCH, base: root.to_s)
         .reject { %w[. ..].include?(File.basename(_1)) }
         .sort
    end

    def zip_signature?(path)
      path.open('rb') { _1.read(ZIP_SIGNATURE.bytesize) } == ZIP_SIGNATURE
    end
    private_class_method :zip_signature?

    # Member names differing only by case land on one path on a case-insensitive volume.
    def unused_path(target)
      return target unless target.exist?

      suffix = 2
      suffix += 1 while Pathname.new("#{target}~#{suffix}").exist?
      Pathname.new("#{target}~#{suffix}")
    end
    private_class_method :unused_path

    def member_target(destination, name)
      relative = name.sub(%r{\A/+}, '')
      Pathname.new(File.expand_path(relative, destination))
    end
    private_class_method :member_target
  end
end
