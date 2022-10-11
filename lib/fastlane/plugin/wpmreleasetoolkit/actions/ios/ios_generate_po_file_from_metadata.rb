require_relative '../../helper/po_extended'
require 'fastlane/action'
require 'gettext/po'

module Fastlane
  module Actions
    class IosGeneratePoFileFromMetadataAction < Action
      # SPECIAL_KEYS are keys that need to be treated specially
      SPECIAL_KEYS = %w[release_notes release_notes_previous].freeze
      REQUIRED_KEYS_TO_COMMENT_HASH = {
        release_notes: 'Multi-paragraph text used to display in the Play Store. Limit to 4000 characters including spaces and commas!',
        name: 'The application name in the Apple App Store. Please keep the brand names (\'Jetpack\' and WordPress\') verbatim. Limit to 30 characters including spaces and punctuation!',
        subtitle: 'Subtitle to be displayed below the application name in the Apple App Store. Limit to 30 characters including spaces and commas!',
        description: 'Multi-paragraph text used to display in the Apple App Store.',
        keywords: 'Keywords used in the App Store search engine to find the app.
.Delimit with a comma between each keyword. Limit to 100 characters including spaces and commas.',
        release_notes_previous: nil
      }.freeze

      REQUIRED_KEYS = REQUIRED_KEYS_TO_COMMENT_HASH.keys.map(&:to_s).freeze
      # rubocop: disable Naming/VariableNumber
      OPTIONAL_KEYS_TO_COMMENT_HASH = {
        promo_screenshot_1: 'Description for the first app store image',
        promo_screenshot_2: 'Description for the second app store image',
        promo_screenshot_3: 'Description for the third app store image',
        promo_screenshot_4: 'Description for the fourth app store image',
        promo_screenshot_5: 'Description for the fifth app store image',
        promo_screenshot_6: 'Description for the sixth app store image'
      }.freeze
      # rubocop: enable Naming/VariableNumber
      KEYS_TO_COMMENT_HASH = REQUIRED_KEYS_TO_COMMENT_HASH.merge(OPTIONAL_KEYS_TO_COMMENT_HASH).freeze

      def self.required_keys
        REQUIRED_KEYS
      end

      def self.run(params)
        metadata_directory = params[:metadata_directory]
        release_version = params[:release_version]
        other_sources = params[:other_sources]

        po = Fastlane::Helper::GeneratePoFileMetadataHelper.new(
          keys_to_comment_hash: KEYS_TO_COMMENT_HASH,
          other_sources: other_sources,
          prefix: 'app_store_'
        )
        po.do(metadata_directory: metadata_directory, special_keys: SPECIAL_KEYS)

        # Now handle release_notes.txt
        release_notes_file = File.join(metadata_directory, 'release_notes.txt')
        po.add_release_notes_to_po(release_notes_file, release_version)

        # Handle release_notes_previous.txt
        release_notes_previous_file = File.join(metadata_directory, 'release_notes_previous.txt')
        version_minus_one = Fastlane::Helper::Android::VersionHelper.calc_prev_release_version(release_version)
        po.add_release_notes_to_po(release_notes_previous_file, version_minus_one)
        po.write(write_to: File.join(metadata_directory, 'AppStoreStrings.po'))

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
            description: 'The path containing the .txt files ',
            is_string: true,
            verify_block: proc do |value|
              UI.user_error!("No metadata_directory path for AnGeneratePoFileFromMetadataAction given, pass using `metadata_directory: 'directory'`") unless value && !value.empty?
              UI.user_error!("Couldn't find path '#{value}'") unless Dir.exist?(value)

              # Check that all required files are in metadata_directory
              @txt_files_in_metadata_directory = Dir[File.join(value, '*.txt')].map { |file| File.basename(file, '.txt') }.to_set
              intersection = @txt_files_in_metadata_directory.intersection(REQUIRED_KEYS.to_set)
              UI.user_error!("One or more mandatory files are missing. You need to have all #{REQUIRED_KEYS.map { |el| "#{el}.txt" }.join(', ')}") unless intersection.length == REQUIRED_KEYS.to_set.length
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :release_version,
            env_name: "#{env_name_prefix}_RELEASE_VERSION",
            description: 'The release version of the app (to use to mark the release notes)',
            verify_block: proc do |value|
              UI.user_error!("No release version for AnGeneratePoFileFromMetadataAction given, pass using `release_version: 'version'`") unless value && !value.empty?
            end
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
