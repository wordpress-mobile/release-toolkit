module Fastlane
  module Actions
    class IosDownloadStringsFilesFromGlotpressAction < Action
      def self.run(params)
        # TODO: Once we introduce the `Locale` POD via #296, check if the param is an array of locales and if so convert it to Hash{glotpress=>lproj}
        locales = params[:locales]
        download_dir = params[:download_dir]

        UI.user_error!("The parent directory `#{download_dir}` (which contains all the `*.lproj` subdirectories) must already exist") unless Dir.exist?(download_dir)

        locales.each do |glotpress_locale, lproj_name|
          # Download the export in the proper `.lproj` directory
          UI.message "Downloading translations for '#{lproj_name}' from GlotPress (#{glotpress_locale}) [#{params[:filters]}]..."
          lproj_dir = File.join(download_dir, "#{lproj_name}.lproj")
          destination = File.join(lproj_dir, "#{params[:table_basename]}.strings")
          FileUtils.mkdir_p(lproj_dir)

          Fastlane::Helper::Ios::L10nHelper.download_glotpress_export_file(
            project_url: params[:project_url],
            locale: glotpress_locale,
            filters: params[:filters],
            destination: destination
          )
          # Do a quick check of the downloaded `.strings` file to ensure it looks valid
          validate_strings_file(destination) unless params[:skip_file_validation]
        end
      end

      # Validate that a `.strings` file downloaded from GlotPress seems valid and does not contain empty translations
      def self.validate_strings_file(destination)
        return unless File.exist?(destination) # If the file failed to download, don't try to validate an non-existing file. We'd already have a separate error for the download failure anyway.

        translations = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: destination)
        empty_keys = translations.select { |_, value| value.nil? || value.empty? }.keys.sort
        unless empty_keys.empty?
          UI.error(
            "Found empty translations in `#{destination}` for the following keys: #{empty_keys.inspect}.\n" \
              + "This is likely a GlotPress bug, and will lead to copies replaced by empty text in the UI.\n" \
              + 'Please report this to the GlotPress team, and fix the file locally before continuing.'
          )
        end
      rescue StandardError => e
        UI.error("Error while validating the file exported from GlotPress (`#{destination}`) - #{e.message.chomp}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Downloads the `.strings` files from GlotPress for the various locales'
      end

      def self.details
        <<~DETAILS
          Downloads the `.strings` files from GlotPress for the various locales,
          validates them, and saves them in the relevant `*.lproj` directories for each locale
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :project_url,
                                       env_name: 'FL_IOS_DOWNLOAD_STRINGS_FILES_FROM_GLOTPRESS_PROJECT_URL',
                                       description: 'URL to the GlotPress project',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :locales,
                                       env_name: 'FL_IOS_DOWNLOAD_STRINGS_FILES_FROM_GLOTPRESS_LOCALES',
                                       description: 'The map of locales to download, each entry of the Hash corresponding to a { glotpress-locale-code => lproj-folder-basename } pair',
                                       type: Hash), # TODO: also support an Array of `Locale` POD/struct type when we introduce it later (see #296)
          FastlaneCore::ConfigItem.new(key: :download_dir,
                                       env_name: 'FL_IOS_DOWNLOAD_STRINGS_FILES_FROM_GLOTPRESS_DOWNLOAD_DIR',
                                       description: 'The parent directory containing all the `*.lproj` subdirectories in which the downloaded files will be saved',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :table_basename,
                                       env_name: 'FL_IOS_DOWNLOAD_STRINGS_FILES_FROM_GLOTPRESS_TABLE_BASENAME',
                                       description: 'The basename to save the `.strings` files under',
                                       type: String,
                                       optional: true,
                                       default_value: 'Localizable'),
          FastlaneCore::ConfigItem.new(key: :filters,
                                       env_name: 'FL_IOS_DOWNLOAD_STRINGS_FILES_FROM_GLOTPRESS_FILTERS',
                                       description: 'The GlotPress filters to use when requesting the translations export',
                                       type: Hash,
                                       optional: true,
                                       default_value: { status: 'current' }),
          FastlaneCore::ConfigItem.new(key: :skip_file_validation,
                                       env_name: 'FL_IOS_DOWNLOAD_STRINGS_FILES_FROM_GLOTPRESS_SKIP_FILE_VALIDATION',
                                       description: 'If true, skips the validation of `.strings` files after download',
                                       type: Fastlane::Boolean,
                                       optional: true,
                                       default_value: false),
        ]
      end

      def self.return_type
        # Describes what type of data is expected to be returned
        # see RETURN_TYPES in https://github.com/fastlane/fastlane/blob/master/fastlane/lib/fastlane/action.rb
      end

      def self.return_value
        # Textual description of what the return value is
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
