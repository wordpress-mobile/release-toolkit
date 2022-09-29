require 'fastlane/action'
require 'gettext/po'

module Fastlane
  module Actions
    class AnGeneratePoFileFromMetadataAction < Action
      def self.run(params)
        # Testing helper function
        # require_relative '../../helper/generate_po_file_from_metadata_helper'
        # po = GetText::PO.new
        # Fastlane::Helper::GeneratePoFileMetadataHelper.add_to_po(folder_path: params[:metadata_directory], prefix: 'play_store', po_object: po);
        # TODO: delegate most of the logic down below to `../../helper/generate_po_file_from_metadata_helper`

        @po = GetText::PO.new
        folder_path = params[:metadata_directory]
        release_version = params[:release_version]
        prefix = 'play_store'
        @rel_note_key = 'release_note'
        Dir[File.join(folder_path, '*.txt')].each do |txt_file|

          file_name = File.basename(txt_file, '.*')
          case file_name
          when 'release_notes'
            values = release_version.split('.')
            version_major = Integer(values[0])
            version_minor = Integer(values[1])
            # Keeps theis shenanigan?
            key = "#{@rel_note_key}_#{version_major.to_s.rjust(2, '0')}#{version_minor}"

            content = <<~TMP
              #{release_version}
              #{File.open(txt_file).read}
            TMP
          else
            # Standard key handling
            content = File.open(txt_file).read
            key = "#{prefix}_#{file_name}"
          end
          @po[key, content] = ''
        end

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

