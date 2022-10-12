require 'gettext/po'
require_relative '../helper/po_extended'

module Fastlane
  module Helper
    class GeneratePoFileMetadataHelper
      def initialize(keys_to_comment_hash:, other_sources:, metadata_directory:, release_version:, po_output_file:, prefix: '')
        @po = PoExtended.new(:msgctxt)
        @keys_to_comment_hash = keys_to_comment_hash
        @other_sources = other_sources
        @metadata_directory = metadata_directory
        @release_version = release_version
        @po_output_file = po_output_file
        @prefix = prefix
      end

      def do(metadata_directory:, special_keys:)
        @po = PoExtended.new(:msgctxt)
        @po[''] = <<~HEADER
          MIME-Version: 1.0
          Content-Type: text/plain; charset=UTF-8
          Content-Transfer-Encoding: 8bit
          Plural-Forms: nplurals=2; plural=n != 1;
          Project-Id-Version: Release Notes & Apple Store Description
          POT-Creation-Date:
          Last-Translator:
          Language-Team:
          Language-Team:
        HEADER

        @po[''].translator_comment = <<~HEADER_COMMENT
          Translation of Release Notes & Apple Store Description in English (US)
          This file is distributed under the same license as the Release Notes & Apple Store Description package.
        HEADER_COMMENT

        all_files_in_metadata_directory = Dir[File.join(metadata_directory, '*.txt')]

        # Remove from all_files_in_metadata_directory the special keys as they need to be treated specially
        standard_files = []
        all_files_in_metadata_directory.each do |key|
          standard_files.append(key) unless special_keys.include? File.basename(key, '.txt')
        end

        # Let the helper handle standard files
        add_standard_files_to_po(files: standard_files)

        other_sources_files = []
        @other_sources.each do |other_source|
          other_sources_files.append(Dir[File.join(other_source, '*.txt')]).flatten!
        end
        add_standard_files_to_po(files: other_sources_files)
        add_release_notes_to_po(File.join(@metadata_directory, 'release_notes.txt'), @release_version)
      end

      def add_poentry_to_po(msgctxt, msgid, translator_comment)
        entry = GetText::POEntry.new(:msgctxt)
        entry.msgid = msgid
        entry.msgctxt = msgctxt
        entry.translator_comment = translator_comment
        entry.msgstr = ''
        @po[entry.msgctxt, entry.msgid] = entry
      end

      def comment(key:)
        if (@keys_to_comment_hash.key? key.to_sym) && (!@keys_to_comment_hash[key.to_sym].nil? && !@keys_to_comment_hash[key.to_sym].empty?)
          ".translators: #{@keys_to_comment_hash[key.to_sym]}"
        else
          ''
        end
      end

      def add_standard_files_to_po(files: [])
        files.each do |file_name|
          key = File.basename(file_name, '.txt')
          msgctxt = "#{@prefix}#{key}"
          msgid = File.open(file_name).read
          add_poentry_to_po(msgctxt, msgid, comment(key: key))
        end
      end

      def add_release_notes_to_po(release_notes_path, version, short: false)
        values = version.split('.')
        version_major = Integer(values[0])
        version_minor = Integer(values[1])
        key_start = 'release_note_'
        if short
          key_start += 'short_'
        end

        interpolated_key = "#{key_start}#{version_major.to_s.rjust(2, '0')}#{version_minor}"

        msgctxt = "#{@prefix}#{interpolated_key}"
        msgid = <<~MSGID
          #{version}
          #{File.open(release_notes_path).read}
        MSGID
        key = File.basename(release_notes_path, '.txt')
        add_poentry_to_po(msgctxt, msgid, comment(key: key))
      end

      def write
        File.write(File.join(@metadata_directory, @po_output_file), @po.to_s)
      end
    end
  end
end
