# frozen_string_literal: true

require 'tempfile'
require_relative '../../helper/config_item_helper'

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

          download_and_replace_strings_file(
            project_url: params[:project_url],
            locale: glotpress_locale,
            filters: params[:filters],
            destination: destination,
            table_basename: params[:table_basename],
            skip_file_validation: params[:skip_file_validation],
            fail_on_error: params[:fail_on_error]
          )
        end
      end

      def self.download_and_replace_strings_file(project_url:, locale:, filters:, destination:, table_basename:, skip_file_validation:, fail_on_error:)
        if File.exist?(destination) && !File.file?(destination)
          report_error("The destination `#{destination}` exists but is not a regular file", fail_on_error: fail_on_error)
          return false
        end

        destination_mode = File.exist?(destination) ? File.stat(destination).mode & 0o7777 : 0o644
        Tempfile.create([table_basename, '.strings'], File.dirname(destination)) do |temporary_file|
          downloaded = Fastlane::Helper::Ios::L10nHelper.download_glotpress_export_file(
            project_url: project_url,
            locale: locale,
            filters: filters,
            destination: temporary_file,
            fail_on_error: fail_on_error
          )
          return false unless downloaded

          temporary_file.flush
          # Do a quick check of the downloaded `.strings` file to ensure it looks valid
          validate_strings_file(temporary_file.path, display_path: destination, fail_on_error: fail_on_error) unless skip_file_validation
          File.chmod(destination_mode, temporary_file.path)
          temporary_file.close
          File.rename(temporary_file.path, destination)
        end
        true
      rescue FastlaneCore::Interface::FastlaneError
        raise
      rescue StandardError => e
        report_error("Error writing downloaded locale `#{locale}` — #{e.message} (#{destination})", fail_on_error: fail_on_error)
        false
      end
      private_class_method :download_and_replace_strings_file

      # Validate that a `.strings` file downloaded from GlotPress seems valid and does not contain empty translations
      def self.validate_strings_file(path, display_path: path, fail_on_error: false)
        unless File.exist?(path)
          report_error("The file exported from GlotPress was not created (`#{display_path}`)", fail_on_error: fail_on_error) if fail_on_error
          return
        end

        if File.empty?(path)
          report_error("The file exported from GlotPress is empty (`#{display_path}`)", fail_on_error: fail_on_error) if fail_on_error
          return
        end

        translations = nil
        begin
          translations = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: path)
        rescue StandardError => e
          report_error("Error while validating the file exported from GlotPress (`#{display_path}`) - #{e.message.chomp}", fail_on_error: fail_on_error)
          return
        end

        unless translations.is_a?(Hash) && translations.all? { |key, value| key.is_a?(String) && value.is_a?(String) }
          report_error("The file exported from GlotPress is not a string-to-string dictionary (`#{display_path}`)", fail_on_error: fail_on_error)
          return
        end

        empty_keys = translations.select { |_, value| value.nil? || value.empty? }.keys.sort
        return if empty_keys.empty?

        report_error(
          "Found empty translations in `#{display_path}` for the following keys: #{empty_keys.inspect}.\n" \
            + "This is likely a GlotPress bug, and will lead to copies replaced by empty text in the UI.\n" \
            + 'Please report this to the GlotPress team, and fix the file locally before continuing.',
          fail_on_error: fail_on_error
        )
      end

      def self.report_error(message, fail_on_error:)
        fail_on_error ? UI.user_error!(message) : UI.error(message)
      end
      private_class_method :report_error

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
          Fastlane::Helper::ConfigItemHelper.opt_in_fail_on_error_config_item,
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
