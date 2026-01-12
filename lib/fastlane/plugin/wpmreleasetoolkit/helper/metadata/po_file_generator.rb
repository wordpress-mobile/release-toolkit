# frozen_string_literal: true

require 'gettext/po'
require 'gettext/po_entry'
require 'gettext/po_parser'

module Fastlane
  module Helper
    # Generates PO/POT files from source text files.
    #
    # This class generates gettext PO files from a hash of source files,
    # handling special cases like versioned release notes and what's new entries.
    #
    # @example Basic usage with file paths
    #   generator = PoFileGenerator.new(
    #     release_version: '1.0',
    #     source_files: {
    #       app_name: '/path/to/name.txt',
    #       description: '/path/to/desc.txt'
    #     }
    #   )
    #
    # @example With translator comments
    #   generator = PoFileGenerator.new(
    #     release_version: '1.0',
    #     source_files: {
    #       app_store_subtitle: {
    #         path: '/path/to/subtitle.txt',
    #         comment: 'translators: Limit to 30 characters!'
    #       },
    #       description: '/path/to/desc.txt'  # no comment
    #     }
    #   )
    class PoFileGenerator
      # @param release_version [String] The release version (e.g., "1.23")
      # @param source_files [Hash] A hash mapping keys to file paths (String) or hashes with :path and :comment keys
      # @param existing_po_path [String, nil] Optional path to existing PO file (needed for release_note to preserve n-1)
      def initialize(release_version:, source_files:, existing_po_path: nil)
        @release_version = release_version
        @source_files = source_files
        @existing_po_path = existing_po_path
      end

      # Generates the PO file content as a string
      # @return [String] The generated PO file content
      def generate
        po = GetText::PO.new

        # Preserve header from existing PO file if available
        add_header(po)

        # Collect all entries first, then sort by msgctxt for deterministic output
        entries = []
        @source_files.each do |key, value|
          path, comment = extract_path_and_comment(value)
          content = File.read(path)
          entries.concat(create_entries_for_key(key.to_sym, content, comment))
        end

        # Sort entries alphabetically by msgctxt and add to PO
        entries.sort_by(&:msgctxt).each do |entry|
          po[entry.msgctxt, entry.msgid] = entry
        end

        # GetText::PO#to_s doesn't add a trailing newline, but our tests expect one
        "#{po}\n"
      end

      # Writes the generated PO content to a file
      # @param output_path [String] The path to write to
      def write(output_path)
        File.write(output_path, generate)
      end

      private

      def add_header(po_data)
        return unless @existing_po_path && File.exist?(@existing_po_path)

        existing_po = GetText::PO.new
        parser = GetText::POParser.new
        parser.parse_file(@existing_po_path, existing_po)

        # Get the header entry (empty msgid)
        header = existing_po['']
        return unless header

        # Update PO-Revision-Date to current time
        updated_msgstr = update_revision_date(header.msgstr)

        # Create new header entry preserving comments
        new_header = GetText::POEntry.new(:normal)
        new_header.msgid = ''
        new_header.msgstr = updated_msgstr
        new_header.translator_comment = header.translator_comment if header.translator_comment

        po_data[new_header.msgctxt, new_header.msgid] = new_header
      rescue StandardError
        # If header parsing fails, continue without header
        nil
      end

      def update_revision_date(msgstr)
        return msgstr unless msgstr

        current_time = Time.now.strftime('%Y-%m-%d %H:%M%z')
        msgstr.gsub(/PO-Revision-Date:.*\n/, "PO-Revision-Date: #{current_time}\n")
      end

      # Extracts path and comment from a source_files value
      # @param value [String, Hash] Either a file path string or a hash with :path and optional :comment
      # @return [Array<String, String|nil>] A tuple of [path, comment]
      def extract_path_and_comment(value)
        case value
        when String
          [value, nil]
        when Hash
          [value[:path], value[:comment]]
        else
          raise ArgumentError, "Invalid source_files value: expected String or Hash, got #{value.class}"
        end
      end

      def create_entries_for_key(key, content, comment = nil)
        case key
        when :whats_new
          [create_whats_new_entry(content, comment)]
        when :release_note
          create_release_note_entries(content, comment)
        when :release_note_short
          create_release_note_short_entries(content, comment)
        else
          [create_standard_entry(key.to_s, content, comment)]
        end
      end

      def create_standard_entry(msgctxt, content, comment = nil)
        create_entry(msgctxt, content.rstrip, comment)
      end

      def create_whats_new_entry(content, comment = nil)
        msgctxt = "v#{@release_version}-whats-new"
        # Ensure content ends with newline for multiline formatting
        msgid = content.end_with?("\n") ? content : "#{content}\n"
        create_entry(msgctxt, msgid, comment)
      end

      def create_release_note_entries(content, comment = nil)
        entries = []

        # Generate new entry for current version
        new_key = release_note_key_for_version(@release_version)
        msgid = "#{@release_version}:\n#{content}"
        msgid = "#{msgid}\n" unless msgid.end_with?("\n")
        entries << create_entry(new_key, msgid, comment)

        # Preserve the n-1 entry from existing file if available
        previous_entry = find_previous_release_note(:release_note)
        entries << previous_entry if previous_entry

        entries
      end

      def create_release_note_short_entries(content, comment = nil)
        return [] if content.strip.empty?

        entries = []

        # Generate new entry for current version
        new_key = release_note_short_key_for_version(@release_version)
        msgid = "#{@release_version}:\n#{content}"
        msgid = "#{msgid}\n" unless msgid.end_with?("\n")
        entries << create_entry(new_key, msgid, comment)

        # Preserve the n-1 entry from existing file if available
        previous_entry = find_previous_release_note(:release_note_short)
        entries << previous_entry if previous_entry

        entries
      end

      def find_previous_release_note(type)
        return nil unless @existing_po_path && File.exist?(@existing_po_path)

        keep_key = case type
                   when :release_note
                     release_note_key_for_previous_version(@release_version)
                   when :release_note_short
                     release_note_short_key_for_previous_version(@release_version)
                   end

        find_entry_in_existing_po(keep_key)
      end

      def find_entry_in_existing_po(target_msgctxt)
        existing_po = GetText::PO.new
        parser = GetText::POParser.new
        parser.parse_file(@existing_po_path, existing_po)

        existing_po.find { |entry| entry.msgctxt == target_msgctxt }
      rescue StandardError
        nil
      end

      def create_entry(msgctxt, msgid, comment = nil)
        entry = GetText::POEntry.new(:msgctxt)
        entry.msgctxt = msgctxt
        entry.msgid = msgid
        entry.msgstr = ''
        entry.extracted_comment = comment if comment
        entry
      end

      def release_note_key_for_version(version)
        major, minor = parse_version(version)
        "release_note_#{major.to_s.rjust(2, '0')}#{minor}"
      end

      def release_note_key_for_previous_version(version)
        major, minor = previous_version(version)
        "release_note_#{major.to_s.rjust(2, '0')}#{minor}"
      end

      def release_note_short_key_for_version(version)
        major, minor = parse_version(version)
        "release_note_short_#{major.to_s.rjust(2, '0')}#{minor}"
      end

      def release_note_short_key_for_previous_version(version)
        major, minor = previous_version(version)
        "release_note_short_#{major.to_s.rjust(2, '0')}#{minor}"
      end

      def parse_version(version)
        parts = version.split('.')
        [Integer(parts[0]), Integer(parts[1])]
      end

      def previous_version(version)
        major, minor = parse_version(version)
        if minor.zero?
          major -= 1
          minor = 9
        else
          minor -= 1
        end
        [major, minor]
      end
    end
  end
end
