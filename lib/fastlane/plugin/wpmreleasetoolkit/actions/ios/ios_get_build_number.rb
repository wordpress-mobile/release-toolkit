module Fastlane
  module Actions
    class IosGetBuildNumberAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper'

        xcconfig_file_path = params[:xcconfig_file_path]
        Fastlane::Helper::Ios::VersionHelper.read_build_number_from_config_file(xcconfig_file_path)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gets the build number of the app'
      end

      def self.details
        'Gets the build number of the app'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :xcconfig_file_path,
            env_name: 'FL_IOS_XCCONFIG_FILE_PATH',
            description: 'Path to the .xcconfig file containing the build number',
            is_string: false,
            optional: false
          )
        ]
      end

      def self.output
        # Define the shared values you are going to provide
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
        'Return the build number of the app'
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['Automattic']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
