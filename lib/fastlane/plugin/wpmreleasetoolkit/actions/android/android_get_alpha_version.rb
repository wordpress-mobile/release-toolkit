module Fastlane
  module Actions
    class AndroidGetAlphaVersionAction < Action
      def self.run(params)
        return unless UI.confirm("#{deprecated_notes} Would you like to continue with the action?")

        require_relative '../../helper/android/android_version_helper'
        Fastlane::Helper::Android::VersionHelper.get_alpha_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        '(DEPRECATED) Gets the alpha version of the app'
      end

      def self.details
        '(DEPRECATED) Gets the alpha version of the app'
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
        ['Automattic']
      end

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        'This action is deprecated because as far as we know, no Android apps that use the Release Toolkit have alpha builds. If that is incorrect, please let the Apps Infrastructure team know on Slack. For other types of version numbers, please use the `version` action to retrieve them.'
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
