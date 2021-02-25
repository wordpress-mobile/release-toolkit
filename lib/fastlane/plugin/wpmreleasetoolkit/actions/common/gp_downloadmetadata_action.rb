require 'fastlane/action'
require_relative '../../helper/metadata_download_helper.rb'

module Fastlane
  module Actions
    class GpDownloadmetadataAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Project URL: #{params[:project_url]}"
        UI.message "Locales: #{params[:locales].inspect}"
        UI.message "Source locale: #{params[:source_locale].nil? ? '-' : params[:source_locale]}"
        UI.message "Path: #{params[:download_path]}"

        # Check download path
        Dir.mkdir(params[:download_path]) unless File.exist?(params[:download_path])

        # Download
        downloader = Fastlane::Helper::MetadataDownloader.new(params[:download_path], params[:target_files])

        params[:locales].each do |loc|
          if loc.is_a?(Array)
            puts "Downloading language: #{loc[1]}"
            complete_url = "#{params[:project_url]}#{loc[0]}/default/export-translations?filters[status]=current&format=json"
            downloader.download(loc[1], complete_url, loc[1] == params[:source_locale])
          end

          if loc.is_a?(String)
            puts "Downloading language: #{loc}"
            complete_url = "#{params[:project_url]}#{loc}/default/export-translations?filters[status]=current&format=json"
            downloader.download(loc, complete_url, loc == params[:source_locale])
          end
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Download translated metadata'
      end

      def self.details
        'Downloads tranlated metadata from GlotPress and updates local files'
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :project_url,
                                       env_name: 'FL_DOWNLOAD_METADATA_PROJECT_URL', # The name of the environment variable
                                       description: 'GlotPress project URL'),
          FastlaneCore::ConfigItem.new(key: :target_files,
                                       env_name: 'FL_DOWNLOAD_METADATA_TARGET_FILES',
                                       description: 'The hash with the path to the target files and the key to use to extract their content',
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :locales,
                                       env_name: 'FL_DOWNLOAD_METADATA_LOCALES',
                                       description: 'The hash with the GLotPress locale and the project locale association',
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :source_locale,
                                       env_name: 'FL_DOWNLOAD_METADATA_SOURCE_LOCALE',
                                       description: 'The source locale code',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :download_path,
                                       env_name: 'FL_DOWNLOAD_METADATA_DOWNLOAD_PATH',
                                       description: 'The path of the target files',
                                       is_string: true),
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
        [:ios, :android].include?(platform)
      end
    end
  end
end
