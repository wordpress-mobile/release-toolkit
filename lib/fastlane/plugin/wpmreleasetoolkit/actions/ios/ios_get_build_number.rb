module Fastlane
  module Actions
    class IosGetBuildNumberAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper'

        public_version_xcconfig_file = params[:public_version_xcconfig_file]
        Fastlane::Helper::Ios::VersionHelper.get_xcconfig_build_number(xcconfig_file: public_version_xcconfig_file)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gets the public build number of the app'
      end

      def self.details
        'Gets the public build number of the app'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :public_version_xcconfig_file,
            env_name: 'FL_IOS_PUBLIC_VERSION_XCCONFIG_FILE',
            description: 'Path to the .xcconfig file containing the public build number',
            type: String,
            optional: false
          ),
        ]
      end

      def self.output
        # Define the shared values you are going to provide
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
        'Return the public build number of the app'
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
