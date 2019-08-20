require 'fastlane/action'
require_relative '../../helper/promo_screenshots_helper.rb'

module Fastlane
  module Actions
    class PromoScreenshotsAction < Action
      def self.run(params)
        UI.message "Creating Promo Screenshots"
        UI.message "Original Screenshot Source: #{params[:orig_folder]}"
        UI.message "Translation source: #{params[:metadata_folder]}"
        UI.message "Output Folder: #{params[:output_folder]}"


        unless params[:force] then
          confirm_directory_overwrite(params[:output_folder], "the existing promo screenshots")
        end

        screenshot_gen = Fastlane::Helper::PromoScreenshots.new(
          params[:config_file],
          params[:orig_folder],
          params[:metadata_folder],
          params[:output_folder]
        )

        screenshot_gen.create()
      end

      def self.confirm_directory_overwrite(path, description)
        if (File.exists?(path)) then
          if UI.confirm("Do you want to overwrite #{description}?") then
            FileUtils.rm_rf(path)
            Dir.mkdir(path)
          else
            UI.user_error!("Exiting to avoid overwriting #{description}.")
          end
        else
          Dir.mkdir(path)
        end
      end

      def self.description
        "Generate promo screenshots"
      end

      def self.authors
        ["Lorenzo Mattei"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Creates promo screenshots starting from standard ones"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :orig_folder,
                                   env_name: "PROMOSS_ORIG",
                                description: "The directory containing the original screenshots",
                                   optional: false,
                                  is_string: true),
          FastlaneCore::ConfigItem.new(key: :output_folder,
                                        env_name: "PROMOSS_OUTPUT",
                                     description: "The path of the folder to save the promo screenshots",
                                        optional: false,
                                      is_string: true),

          FastlaneCore::ConfigItem.new(key: :metadata_folder,
                                        env_name: "PROMOSS_METADATA_FOLDER",
                                     description: "The directory containing the translation data",
                                        optional: false,
                                      is_string: true),

          FastlaneCore::ConfigItem.new(key: :config_file,
                                        env_name: "PROMOSS_CONFIG_FILE",
                                     description: "The path to the file containing the promo screenshot configuration",
                                        optional: true,
                                       is_string: true,
                                   default_value: "screenshots.json"),

          FastlaneCore::ConfigItem.new(key: :force,
                                        env_name: "PROMOSS_FORCE_CREATION",
                                     description: "Overwrite existing promo screenshots without asking first?",
                                        optional: true,
                                       is_string: false,
                                   default_value: false),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
