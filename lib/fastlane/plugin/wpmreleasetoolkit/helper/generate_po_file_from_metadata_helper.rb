require 'gettext/po'

module Fastlane
  module Helper
    # Helper methods to execute PO related operations
    #
    module GeneratePoFileMetadataHelper

      # Return a GetText::PO object
      # standard_keys is the list of files
      def self.add_standard_files_to_po(prefix, files: [])
        po_obj = GetText::PO.new
        files.each do |file_name|
          msgid = File.open(file_name).read
          msgctxt = "#{prefix}_#{File.basename(file_name, '.txt')}"
          po_obj[msgctxt, msgid] = ''
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
