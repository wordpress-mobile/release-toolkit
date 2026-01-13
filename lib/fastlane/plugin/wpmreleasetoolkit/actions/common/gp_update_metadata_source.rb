# frozen_string_literal: true

require_relative '../../helper/metadata/po_file_generator'

module Fastlane
  module Actions
    class GpUpdateMetadataSourceAction < Action
      def self.run(params)
        UI.message "PO file path: #{params[:po_file_path]}"
        UI.message "Release version: #{params[:release_version]}"

        # Check local repo status if we're going to commit changes
        other_action.ensure_git_status_clean if params[:commit_changes]

        validate_source_files(params[:source_files])

        generator = Fastlane::Helper::PoFileGenerator.new(
          release_version: params[:release_version],
          source_files: params[:source_files]
        )

        generator.write(params[:po_file_path])

        UI.message "File #{params[:po_file_path]} updated!"

        commit_changes(params) if params[:commit_changes]
      end

      def self.validate_source_files(source_files)
        source_files.each_value do |value|
          file_path = value.is_a?(Hash) ? value[:path] : value
          UI.user_error!("Couldn't find file at path '#{file_path}'") unless File.exist?(file_path)
        end
      end

      def self.commit_changes(params)
        files_to_add = [params[:po_file_path]]
        params[:source_files].each_value do |value|
          file_path = value.is_a?(Hash) ? value[:path] : value
          files_to_add << file_path
        end

        other_action.git_add(path: files_to_add)
        other_action.git_commit(
          path: files_to_add,
          message: 'Update metadata strings',
          allow_nothing_to_commit: true
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates a .po file from source .txt files'
      end

      def self.details
        <<~DETAILS
          Generates a .po file from source .txt files for localization via GlotPress.

          The `source_files` parameter accepts either simple file paths or hashes with path and comment:

          ```ruby
          source_files: {
            # Simple path (no translator comment)
            app_name: 'path/to/name.txt',

            # Hash with path and translator comment
            app_store_subtitle: {
              path: 'path/to/subtitle.txt',
              comment: 'translators: Limit to 30 characters!'
            }
          }
          ```
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :po_file_path,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_PO_FILE_PATH',
                                       description: 'The path of the .po file to generate',
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No .po file path given, pass using `po_file_path: 'file path'`") unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_RELEASE_VERSION',
                                       description: 'The release version of the app (used for release notes)',
                                       verify_block: proc do |value|
                                         UI.user_error!("No release version given, pass using `release_version: 'version'`") unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :source_files,
                                       env_name: 'FL_UPDATE_METADATA_SOURCE_SOURCE_FILES',
                                       description: 'Hash mapping keys to file paths (String) or hashes with :path and optional :comment',
                                       type: Hash,
                                       verify_block: proc do |value|
                                         UI.user_error!("No source files given, pass using `source_files: { key: 'path' }`") unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :commit_changes,
                                       description: 'If true, checks git status is clean, then adds and commits the changes',
                                       type: Boolean,
                                       default_value: false),
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
        true
      end
    end
  end
end
