require 'gettext/po'
require 'gettext/po_entry'

module Fastlane
  module Helper
    # Helper methods to execute PO related operations
    #
    module GeneratePoFileMetadataHelper

      # Return a GetText::PO object
      # standard_keys is the list of files
      def self.add_standard_files_to_po(prefix, keys_to_comment_hash: Hash, files: [])
        po_obj = GetText::PO.new
        files.each do |file_name|
          key = File.basename(file_name, '.txt')
          entry = GetText::POEntry.new(:msgctxt)
          entry.msgid = File.open(file_name).read
          entry.msgctxt = "#{prefix}_#{File.basename(file_name, '.txt')}"
          entry.msgstr = ''
          # if we have comment whose key matches our translation key
          if keys_to_comment_hash.key? key.to_sym
            entry.translator_comment = ".translators: #{keys_to_comment_hash[key.to_sym]}"
          end
          # entry.translator_comment = "It's the translator comment."
          po_obj[entry.msgctxt, entry.msgid] = entry
        end
        po_obj
      end

      def self.add_release_notes_to_po(release_notes_path, version, prefix, po_obj)
        values = version.split('.')
        version_major = Integer(values[0])
        version_minor = Integer(values[1])
        key = "release_note_#{version_major.to_s.rjust(2, '0')}#{version_minor}"

        msgctxt = "#{prefix}_#{key}"
        msgid = <<~MSGID
          #{version}
          #{File.open(release_notes_path).read}
        MSGID

        po_obj[msgctxt, msgid] = ''
        po_obj
      end
    end
  end
end
