require 'gettext/po'

module Fastlane
  module Helper
    # Helper methods to execute PO related operations
    #
    module GeneratePoFileMetadataHelper

      # Return a GetText::PO object
      # standard_keys is the list of files
      def self.add_standard_file_to_po(prefix, files: [])
        po_obj = GetText::PO.new
        files.each do |file_name|
          msgid = File.open(file_name).read
          msgctxt = "#{prefix}_#{File.basename(file_name, '.txt')}"
          po_obj[msgctxt, msgid] = ''
        end
        po_obj
      end
    end
  end
end
