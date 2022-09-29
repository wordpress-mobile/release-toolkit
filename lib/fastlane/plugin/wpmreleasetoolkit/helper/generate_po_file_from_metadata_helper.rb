require 'gettext/po'

module Fastlane
  module Helper
    # Helper methods to execute git-related operations
    #
    module GeneratePoFileMetadataHelper


      def self.add_to_po(folder_path: path, prefix: '', po_object: GetText::PO)

        # Get just the .txt files, there might be the .po as well
        # Dir[File.join(folder_path, '*.txt')].each do |txt_file|
        #
        #   file_name = File.basename(txt_file, '.*')
        #   content = File.open(txt_file).read
        #   key = "#{prefix}_#{file_name}"
        #   po_object[key] = content
        #   # po_object.set_comment("#{prefix}file_name", content)
        # end
        # po_object.set_comment('foo', 'bar')
        # UI.message(po_object.to_s)


      end

    end
  end
end
