# frozen_string_literal: true

require 'gettext/po'
require 'gettext/po_entry'
require_relative '../../version'

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
      def initialize(release_version:, source_files:)
        @release_version = release_version
        @source_files = source_files
      end

      # Generates the PO file content as a string
      # @return [String] The generated PO file content
      def generate
        po = GetText::PO.new
        # Disable GetText's internal sorting so we control entry order via our own sort_by(:msgctxt)
        po.order = :none

        # Add standard PO header
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

        # GetText::PO#to_s doesn't add a trailing newline
        "#{po}\n"
      end

      # Writes the generated PO content to a file
      # @param output_path [String] The path to write to
      def write(output_path)
        File.write(output_path, generate)
      end

      private

      def add_header(po_data)
        revision_date = Time.now.strftime('%Y-%m-%d %H:%M%z')
        generator = "fastlane-plugin-wpmreleasetoolkit #{Fastlane::Wpmreleasetoolkit::VERSION}"

        header_content = <<~HEADER
          PO-Revision-Date: #{revision_date}
          MIME-Version: 1.0
          Content-Type: text/plain; charset=UTF-8
          Content-Transfer-Encoding: 8bit
          Plural-Forms: nplurals=2; plural=n != 1;
          X-Generator: #{generator}
        HEADER

        header = GetText::POEntry.new(:normal)
        header.msgid = ''
        header.msgstr = header_content
        po_data[header.msgctxt, header.msgid] = header
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
        key = release_note_key_for_version(@release_version)
        msgid = "#{@release_version}:\n#{content}"
        msgid = "#{msgid}\n" unless msgid.end_with?("\n")
        [create_entry(key, msgid, comment)]
      end

      def create_release_note_short_entries(content, comment = nil)
        return [] if content.strip.empty?

        key = release_note_short_key_for_version(@release_version)
        msgid = "#{@release_version}:\n#{content}"
        msgid = "#{msgid}\n" unless msgid.end_with?("\n")
        [create_entry(key, msgid, comment)]
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

      def release_note_short_key_for_version(version)
        major, minor = parse_version(version)
        "release_note_short_#{major.to_s.rjust(2, '0')}#{minor}"
      end

      def parse_version(version)
        parts = version.split('.')
        [Integer(parts[0]), Integer(parts[1])]
      end
    end
  end
end
