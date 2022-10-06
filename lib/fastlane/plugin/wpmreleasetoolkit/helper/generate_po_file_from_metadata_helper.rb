require 'gettext/po'

module Fastlane
  module Helper
    # Helper methods to execute PO related operations
    #
    module GeneratePoFileMetadataHelper

      # Return a GetText::PO object
      # standard_keys is the list of files
      def self.add_standard_file_to_po(prefix, files: [], keys_to_comment_hash: {})
        po_obj = GetText::PO.new
        files.each do |file_name|
          msgid = File.open(file_name).read
          key = File.basename(file_name, '.txt')
          msgctxt = "#{prefix}_#{key}"
          entry = GetText::POEntry.new(:msgctxt)
          entry.msgid = msgid
          entry.msgctxt = msgctxt
          entry.msgstr = ''
          if keys_to_comment_hash.key? key.to_sym
            entry.translator_comment = ".translators: #{keys_to_comment_hash[key.to_sym]}"
          end
          # entry.translator_comment = "It's the translator comment."
          po_obj[entry.msgctxt, entry.msgid] = entry
        end
        po_obj
      end

      def self.add_release_notes_to_po(release_notes_path, version, prefix, po_obj, keys_to_comment_hash: {})
        values = version.split('.')
        version_major = Integer(values[0])
        version_minor = Integer(values[1])
        interpolated_key = "release_note_#{version_major.to_s.rjust(2, '0')}#{version_minor}"

        msgctxt = "#{prefix}_#{interpolated_key}"
        msgid = <<~MSGID
          #{version}
          #{File.open(release_notes_path).read}
        MSGID

        entry = GetText::POEntry.new(:msgctxt)
        entry.msgid = msgid
        entry.msgctxt = msgctxt
        entry.msgstr = ''
        key = File.basename(release_notes_path, '.txt')
        if keys_to_comment_hash.key? key.to_sym
          entry.translator_comment = ".translators: #{keys_to_comment_hash[key.to_sym]}"
        end
        po_obj[entry.msgctxt, entry.msgid] = entry

        po_obj[msgctxt, msgid] = ''
        po_obj
      end
    end
  end
end
