# frozen_string_literal: true

require_relative '../../helper/metadata/po_file_generator'

module Fastlane
  module Actions
    class AnUpdateMetadataSourceAction < Action
      def self.run(params)
        UI.message "PO file path: #{params[:po_file_path]}"
        UI.message "Release version: #{params[:release_version]}"

        validate_source_files(params[:source_files])

        generator = Fastlane::Helper::PoFileGenerator.new(
          release_version: params[:release_version],
          source_files: params[:source_files],
          existing_po_path: params[:po_file_path]
        )

        generator.write(params[:po_file_path])

        UI.message "File #{params[:po_file_path]} updated!"
      end

      def self.validate_source_files(source_files)
        source_files.each_value do |file_path|
          UI.user_error!("Couldn't find file at path '#{file_path}'") unless File.exist?(file_path)
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates a .po file from source .txt files'
      end

      def self.details
        'Generates a .po file from source .txt files for localization via GlotPress.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :po_file_path,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_PO_FILE_PATH',
                                       description: 'The path of the .po file to generate',
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No .po file path given, pass using `po_file_path: 'file path'`") unless value && !value.empty?
                                         UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_RELEASE_VERSION',
                                       description: 'The release version of the app (used for release notes)',
                                       verify_block: proc do |value|
                                         UI.user_error!("No release version given, pass using `release_version: 'version'`") unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :source_files,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_SOURCE_FILES',
                                       description: 'Hash mapping keys to source file paths',
                                       type: Hash,
                                       verify_block: proc do |value|
                                         UI.user_error!("No source files given, pass using `source_files: { key: 'path' }`") unless value && !value.empty?
                                       end),
        ]
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end
    end
  end
end
