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
    class PoFileGenerator
      # @param release_version [String] The release version (e.g., "1.23")
      # @param source_files [Hash] A hash mapping keys to file paths
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

        @source_files.each do |key, file_path|
          content = File.read(file_path)
          add_entries_for_key(po, key.to_sym, content)
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

      def add_entries_for_key(po, key, content)
        case key
        when :whats_new
          add_whats_new_entry(po, content)
        when :release_note
          add_release_note_entries(po, content)
        when :release_note_short
          add_release_note_short_entries(po, content)
        else
          add_standard_entry(po, key.to_s, content)
        end
      end

      def add_standard_entry(po, msgctxt, content)
        entry = create_entry(msgctxt, content.rstrip)
        po[entry.msgctxt, entry.msgid] = entry
      end

      def add_whats_new_entry(po, content)
        msgctxt = "v#{@release_version}-whats-new"
        # Ensure content ends with newline for multiline formatting
        msgid = content.end_with?("\n") ? content : "#{content}\n"
        entry = create_entry(msgctxt, msgid)
        po[entry.msgctxt, entry.msgid] = entry
      end

      def add_release_note_entries(po, content)
        # Generate new entry for current version
        new_key = release_note_key_for_version(@release_version)
        msgid = "#{@release_version}:\n#{content}"
        msgid = "#{msgid}\n" unless msgid.end_with?("\n")
        entry = create_entry(new_key, msgid)
        po[entry.msgctxt, entry.msgid] = entry

        # Preserve the n-1 entry from existing file if available
        preserve_previous_release_note(po, :release_note)
      end

      def add_release_note_short_entries(po, content)
        return if content.strip.empty?

        # Generate new entry for current version
        new_key = release_note_short_key_for_version(@release_version)
        msgid = "#{@release_version}:\n#{content}"
        msgid = "#{msgid}\n" unless msgid.end_with?("\n")
        entry = create_entry(new_key, msgid)
        po[entry.msgctxt, entry.msgid] = entry

        # Preserve the n-1 entry from existing file if available
        preserve_previous_release_note(po, :release_note_short)
      end

      def preserve_previous_release_note(po, type)
        return unless @existing_po_path && File.exist?(@existing_po_path)

        keep_key = case type
                   when :release_note
                     release_note_key_for_previous_version(@release_version)
                   when :release_note_short
                     release_note_short_key_for_previous_version(@release_version)
                   end

        existing_entry = find_entry_in_existing_po(keep_key)
        return unless existing_entry

        po[existing_entry.msgctxt, existing_entry.msgid] = existing_entry
      end

      def find_entry_in_existing_po(target_msgctxt)
        existing_po = GetText::PO.new
        parser = GetText::POParser.new
        parser.parse_file(@existing_po_path, existing_po)

        existing_po.find { |entry| entry.msgctxt == target_msgctxt }
      rescue StandardError
        nil
      end

      def create_entry(msgctxt, msgid)
        entry = GetText::POEntry.new(:msgctxt)
        entry.msgctxt = msgctxt
        entry.msgid = msgid
        entry.msgstr = ''
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
