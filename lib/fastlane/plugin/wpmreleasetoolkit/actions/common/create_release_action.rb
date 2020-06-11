require 'fastlane/action'
require 'date'
require_relative '../../helper/ghhelper_helper'
require_relative '../../helper/ios/ios_version_helper'
require_relative '../../helper/android/android_version_helper'
module Fastlane
  module Actions
    class CreateReleaseAction < Action
      def self.run(params)
        repository = params[:repository]
        version = params[:version]
        assets = params[:release_assets]
        release_notes = params[:release_notes_file_path].nil? ? "" : IO.read(params[:release_notes_file_path])

        UI.message("Creating draft release #{version} in #{repository}.")
        # Verify assets
        assets.each do |file_path|
          UI.user_error!("Can't find file #{file_path}!") unless File.exist?(file_path)
        end

        Fastlane::Helper::GhhelperHelper.create_release(repository, version, release_notes, assets)
        UI.message("Done")
      end

      def self.description
        "Creates a release and uploads the provided assets"
      end

      def self.authors
        ["Lorenzo Mattei"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Creates a release and uploads the provided assets"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: "GHHELPER_REPOSITORY",
                                       description: "The remote path of the GH repository on which we work",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "GHHELPER_CREATE_RELEASE_VERSION",
                                       description: "The version of the release",
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path,
                                       env_name: "GHHELPER_CREATE_RELEASE_NOTES",
                                       description: "The path to the file that contains the release notes",
                                       optional: true,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :release_assets,
                                       env_name: "GHHELPER_CREATE_RELEASE_ASSETS",
                                       description: "Assets to upload",
                                       type: Array,
                                       optional: false,),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
