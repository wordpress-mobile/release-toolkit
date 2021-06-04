module Fastlane
  module Actions
    class AndroidGetAlphaVersionAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'
        Fastlane::Helper::Android::VersionHelper.get_alpha_version()
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
        # Define all options your action supports.
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
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
