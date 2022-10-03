require 'fastlane/action'
require 'gettext/po'
require 'set'

module Fastlane
  module Actions
    class AnGeneratePoFileFromMetadataAction < Action
      REQUIRED_KEYS = %w[description keywords name release_notes].freeze
      SPECIAL_KEYS = %w[release_notes].freeze
      def self.run(params)
        @metadata_directory = params[:metadata_directory]
        @release_version = params[:release_version]

        prefix = 'play_store'
        all_keys = Dir[File.join(@metadata_directory, '*.txt')]

        # Remove from all_keys the special keys as they need to be treated specially
        standard_files = []
        all_keys.each do |key|
          standard_files.append(key) unless SPECIAL_KEYS.include? File.basename(key, '.txt')
        end
        # Let the helper handle standard files
        @po = Fastlane::Helper::GeneratePoFileMetadataHelper.add_standard_file_to_po(prefix, files: standard_files)

        # Now handle release_notes.txt
        release_notes_file = Dir[File.join(@metadata_directory, 'release_notes.txt')][0]

        values = @release_version.split('.')
        version_major = Integer(values[0])
        version_minor = Integer(values[1])
        # TODO: Keeps theis shenanigan?
        key = "release_note_#{version_major.to_s.rjust(2, '0')}#{version_minor}"

        msgctxt = "#{prefix}_#{key}"
        msgid = <<~MSGID
          #{@release_version}
          #{File.open(release_notes_file).read}
        MSGID
        @po[msgctxt, msgid] = ''

        # Finally dump the po into PlayStoreStrings.po
        po_file = File.join(params[:metadata_directory], 'PlayStoreStrings.po')
        File.write(po_file, @po.to_s)
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
          FastlaneCore::ConfigItem.new(key: :metadata_directory,
                                       env_name: "#{env_name_prefix}_METADATA_DIRECTORY",
                                       description: 'The path containing the .txt files ',
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No metadata_directory path for AnGeneratePoFileFromMetadataAction given, pass using `metadata_directory: 'directory'`") unless value && (!value.empty?)
                                         UI.user_error!("Couldn't find path '#{value}'") unless Dir.exist?(value)

                                         # Check that all required files are in metadata_directory
                                         @txt_files_in_metadata_directory = Dir[File.join(value, '*.txt')].map { |file| File.basename(file, '.txt') }.to_set
                                         intersection = @txt_files_in_metadata_directory.intersection(REQUIRED_KEYS.to_set)
                                         UI.user_error!('One or more mandatory files are missing') unless intersection.length == REQUIRED_KEYS.to_set.length
                                         # TODO: tell what files are missing
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                       env_name: "#{env_name_prefix}_RELEASE_VERSION",
                                       description: 'The release version of the app (to use to mark the release notes)',
                                       verify_block: proc do |value|
                                         UI.user_error!("No relase version for AnGeneratePoFileFromMetadataAction given, pass using `release_version: 'version'`") unless value && (!value.empty?)
                                       end)

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

