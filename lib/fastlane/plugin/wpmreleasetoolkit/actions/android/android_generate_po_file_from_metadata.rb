require 'fastlane/action'
require 'gettext/po'

module Fastlane
  module Actions
    class AndroidGeneratePoFileFromMetadataAction < Action
      # SPECIAL_KEYS are keys that need to be treated specially
      SPECIAL_KEYS = %w[release_notes release_notes_previous release_notes_short].freeze
      KNOWN_KEYS_TO_COMMENTS = {
        full_description: 'Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!',
        title: 'Title to be displayed in the Play Store. Limit to 30 characters including spaces and commas!',
        short_description: 'Short description of the app to be displayed in the Play Store. Limit to 80 characters including spaces and commas!',
        release_notes_short: 'Shorter Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!',
        release_notes: 'Release notes for this version to be displayed in the Play Store. Limit to 500 characters including spaces and commas!'
      }.freeze
      REQUIRED_KEYS = %w[full_description title short_description release_notes].freeze

      def self.run(params)
        metadata_directory = params[:metadata_directory]
        release_version = params[:release_version]
        other_sources = params[:other_sources]

        po = Fastlane::Helper::GeneratePoFileMetadataHelper.new(
          keys_to_comment_hash: KNOWN_KEYS_TO_COMMENTS,
          other_sources: other_sources,
          release_version: release_version,
          metadata_directory: metadata_directory,
          prefix: 'play_store_'
        )
        po.do(metadata_directory: metadata_directory, special_keys: SPECIAL_KEYS)

        # Now handle release_notes_short.txt
        release_notes_file = File.join(metadata_directory, 'release_notes_short.txt')
        if File.exist? release_notes_file
          po.add_release_notes_to_po(release_notes_file, release_version, short: true)
        else
          UI.important("#{release_notes_file} does not exist!")
        end

        # Handle release_notes_previous.txt
        release_notes_previous_file = File.join(metadata_directory, 'release_notes_previous.txt')
        if File.exist? release_notes_previous_file
          version_minus_one = Fastlane::Helper::Android::VersionHelper.calc_prev_release_version(release_version)
          po.add_release_notes_to_po(release_notes_previous_file, version_minus_one)
        else
          UI.important("#{release_notes_previous_file} does not exist!")
        end

        po.write(po_output_file: 'PlayStoreStrings.po')
      end

      def self.description
        'Create the .po based on the .txt files in metadata_directory'
      end

      def self.details
        'You can use this action to update the .po file that contains the string to load to GlotPress for localization.'
      end

      def self.available_options
        # Define all options your action supports.

        env_name_prefix = 'FL_GENERATE_PO_FILE_FROM_METADATA'
        [
          FastlaneCore::ConfigItem.new(
            key: :metadata_directory,
            env_name: "#{env_name_prefix}_METADATA_DIRECTORY",
            description: 'The path containing the .txt files',
            optional: false,
            is_string: true,
            verify_block: proc do |value|
              UI.user_error!("Couldn't find path '#{value}'") unless Dir.exist?(value)

              required_keys_exist, message = Fastlane::Helper::GeneratePoFileMetadataHelper.do_required_keys_exist(metadata_folder: value, required_keys: REQUIRED_KEYS)
              UI.user_error!(message) unless required_keys_exist
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :release_version,
            env_name: "#{env_name_prefix}_RELEASE_VERSION",
            description: 'The release version of the app (to use to mark the release notes)',
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :other_sources,
            type: Array,
            default_value: [],
            env_name: "#{env_name_prefix}_OTHER_SOURCES",
            description: 'Other directories that contain files to be added to the po',
            verify_block: proc do |value|
              value.each do |other_sources_dir|
                UI.user_error!("#{other_sources_dir} does not exist.") unless Dir.exist? other_sources_dir
              end
            end
          ),

        ]
      end

      def self.output
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
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
