# frozen_string_literal: true

require 'tempfile'

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

          unless params[:fail_on_error]
            Fastlane::Helper::Ios::L10nHelper.download_glotpress_export_file(
              project_url: params[:project_url],
              locale: glotpress_locale,
              filters: params[:filters],
              destination: destination
            )
            validate_strings_file(destination) unless params[:skip_file_validation]
            next
          end

          destination_mode = File.exist?(destination) ? File.stat(destination).mode & 0o7777 : 0o644
          Tempfile.create([params[:table_basename], '.strings'], lproj_dir) do |temporary_file|
            downloaded = Fastlane::Helper::Ios::L10nHelper.download_glotpress_export_file(
              project_url: params[:project_url],
              locale: glotpress_locale,
              filters: params[:filters],
              destination: temporary_file,
              fail_on_error: true
            )
            next unless downloaded

            temporary_file.flush
            # Do a quick check of the downloaded `.strings` file to ensure it looks valid
            validate_strings_file(temporary_file.path, display_path: destination, fail_on_error: true) unless params[:skip_file_validation]
            File.chmod(destination_mode, temporary_file.path)
            temporary_file.close
            FileUtils.mv(temporary_file.path, destination)
          end
        end
      end

      # Validate that a `.strings` file downloaded from GlotPress seems valid and does not contain empty translations
      def self.validate_strings_file(path, display_path: path, fail_on_error: false)
        unless File.exist?(path)
          report_validation_error("The file exported from GlotPress was not created (`#{display_path}`)", fail_on_error: fail_on_error) if fail_on_error
          return
        end

        if File.empty?(path)
          report_validation_error("The file exported from GlotPress is empty (`#{display_path}`)", fail_on_error: fail_on_error) if fail_on_error
          return
        end

        translations = nil
        begin
          translations = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: path)
        rescue StandardError => e
          report_validation_error("Error while validating the file exported from GlotPress (`#{display_path}`) - #{e.message.chomp}", fail_on_error: fail_on_error)
          return
        end

        empty_keys = translations.select { |_, value| value.nil? || value.empty? }.keys.sort
        return if empty_keys.empty?

        report_validation_error(
          "Found empty translations in `#{display_path}` for the following keys: #{empty_keys.inspect}.\n" \
            + "This is likely a GlotPress bug, and will lead to copies replaced by empty text in the UI.\n" \
            + 'Please report this to the GlotPress team, and fix the file locally before continuing.',
          fail_on_error: fail_on_error
        )
      end

      def self.report_validation_error(message, fail_on_error:)
        fail_on_error ? UI.user_error!(message) : UI.error(message)
      end
      private_class_method :report_validation_error

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
          FastlaneCore::ConfigItem.new(key: :fail_on_error,
                                       env_name: 'FL_IOS_DOWNLOAD_STRINGS_FILES_FROM_GLOTPRESS_FAIL_ON_ERROR',
                                       description: 'Whether to fail when a GlotPress request or downloaded response is invalid',
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
        %i[ios mac].include?(platform)
      end
    end
  end
end
