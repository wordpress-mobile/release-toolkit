require 'gettext/po'
require_relative '../helper/po_extended'

module Fastlane
  module Helper
    # Helper methods to execute PO related operations
    #
    module GeneratePoFileMetadataHelper
      def self.do(prefix:, metadata_directory:, special_keys:, keys_to_comment_hash:, other_sources:)
        po = PoExtended.new(:msgctxt)
        po[''] = <<~HEADER
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

        po[''].translator_comment = <<~HEADER_COMMENT
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
        po = add_standard_files_to_po(prefix, files: standard_files, keys_to_comment_hash: keys_to_comment_hash, po_obj: po)

        other_sources_files = []
        other_sources.each do |other_source|
          other_sources_files.append(Dir[File.join(other_source, '*.txt')]).flatten!
        end
        add_standard_files_to_po(prefix, files: other_sources_files, keys_to_comment_hash: keys_to_comment_hash, po_obj: po)
      end

      def self.add_poentry_to_po(msgctxt, msgid, translator_comment, po_obj)
        entry = GetText::POEntry.new(:msgctxt)
        entry.msgid = msgid
        entry.msgctxt = msgctxt
        entry.translator_comment = translator_comment
        entry.msgstr = ''
        po_obj[entry.msgctxt, entry.msgid] = entry
        po_obj
      end

      def self.add_comment_to_poentry(key:, keys_to_comment_hash:)
        if (keys_to_comment_hash.key? key.to_sym) && (!keys_to_comment_hash[key.to_sym].nil? && !keys_to_comment_hash[key.to_sym].empty?)
          ".translators: #{keys_to_comment_hash[key.to_sym]}"
        else
          ''
        end
      end

      # Return a GetText::PO object
      # standard_keys is the list of files
      def self.add_standard_files_to_po(prefix, files: [], keys_to_comment_hash: {}, po_obj: GetText::PO)
        # po = GetText::PO.new
        files.each do |file_name|
          key = File.basename(file_name, '.txt')
          msgctxt = "#{prefix}#{key}"
          msgid = File.open(file_name).read
          translator_comment = add_comment_to_poentry(key: key, keys_to_comment_hash: keys_to_comment_hash)
          po_obj = add_poentry_to_po(msgctxt, msgid, translator_comment, po_obj)
        end
        po_obj
      end

      def self.add_release_notes_to_po(release_notes_path, version, prefix, po_obj, keys_to_comment_hash: {})
        values = version.split('.')
        version_major = Integer(values[0])
        version_minor = Integer(values[1])
        interpolated_key = "release_note_#{version_major.to_s.rjust(2, '0')}#{version_minor}"

        msgctxt = "#{prefix}#{interpolated_key}"
        msgid = <<~MSGID
          #{version}
          #{File.open(release_notes_path).read}
        MSGID

        key = File.basename(release_notes_path, '.txt')
        translator_comment = add_comment_to_poentry(key: key, keys_to_comment_hash: keys_to_comment_hash)

        add_poentry_to_po(msgctxt, msgid, translator_comment, po_obj)
      end
    end
  end
end
