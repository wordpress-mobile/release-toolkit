module Fastlane
  module Actions
    class AndroidGetAlphaVersionAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'
        Fastlane::Helper::Android::VersionHelper.get_alpha_version(
          params[:build_gradle_path],
          params[:version_properties_path],
          params[:has_alpha_version]
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gets the alpha version of the app'
      end

      def self.details
        'Gets the alpha version of the app'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :build_gradle_path,
                                       description: 'Path to the build.gradle file',
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :version_properties_path,
                                       description: 'Path to the version.properties file',
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :has_alpha_version,
                                       description: 'Whether the app has an alpha version',
                                       type: Boolean,
                                       optional: true),
        ]
      end

      def self.output
        # Define the shared values you are going to provide
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
        'Return the alpha version of the app'
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
