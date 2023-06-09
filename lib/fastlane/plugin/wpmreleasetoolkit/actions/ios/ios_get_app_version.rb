module Fastlane
  module Actions
    class IosGetAppVersionAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper'

        UI.user_error!('You need to set at least the PUBLIC_CONFIG_FILE env var to the path to the public xcconfig file') unless ENV['PUBLIC_CONFIG_FILE']

        Fastlane::Helper::Ios::VersionHelper.get_public_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gets the public version of the app'
      end

      def self.details
        'Gets the public version of the app'
      end

      def self.available_options
        # Define all options your action supports.
      end

      def self.output
        # Define the shared values you are going to provide
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
        'Return the public version of the app'
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
