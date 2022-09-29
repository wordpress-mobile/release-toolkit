require 'gettext/po'

module Fastlane
  module Helper
    # Helper methods to execute git-related operations
    #
    module GeneratePoFileMetadataHelper

      # @return [Array<String>]
      # files that should exist for both iOS and Android
      def self.get_common_keys
        # Not sure if keywords should be included
        %w[description keywords name release_notes name]
      end

      def self.verify_all_required_files_exist(metadata_folder: path)
        txt_files_in_metadata_folder = Dir[File.join(metadata_folder, '*.txt')]
        # If a required file/keys is missing, bail out.
        get_common_keys.each do |must_exist_key|
          puts("file #{must_exist_key}.txt in #{metadata_folder} not found.") unless txt_files_in_metadata_folder.include? "#{must_exist_key}.txt"
        end
      end
    end
  end
end
