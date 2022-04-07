require 'fastlane/action'
require_relative '../../helper/an_metadata_update_helper'

module Fastlane
  module Actions
    class AnUpdateMetadataSourceAction < Action
      def self.category
        :deprecated
      end

      def self.deprecated_notes
        'This action is deprecated. Use `gp_update_metadata_source` instead.'
      end

      def self.run(params)
        other_action.gp_update_metadata_source(
          po_file_path: params[:po_file_path],
          source_files: params[:source_files],
          release_version: params[:release_version]
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Updates a .po file with new data from .txt files'
      end

      def self.details
        'You can use this action to update the .po file that contains the string to load to GlotPress for localization.'
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :po_file_path,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_PO_FILE_PATH',
                                       description: 'The path of the .po file to update',
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No .po file path for UpdateMetadataSourceAction given, pass using `po_file_path: 'file path'`") unless value && (!value.empty?)
                                         UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_RELEASE_VERSION',
                                       description: 'The release version of the app (to use to mark the release notes)',
                                       verify_block: proc do |value|
                                         UI.user_error!("No relase version for UpdateMetadataSourceAction given, pass using `release_version: 'version'`") unless value && (!value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :source_files,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_SOURCE_FILES',
                                       description: 'The hash with the path to the source files and the key to use to include their content',
                                       is_string: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("No source file hash for UpdateMetadataSourceAction given, pass using `source_files: 'source file hash'`") unless value && (!value.empty?)
                                       end),
        ]
      end

      def self.output
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end
    end
  end
end
