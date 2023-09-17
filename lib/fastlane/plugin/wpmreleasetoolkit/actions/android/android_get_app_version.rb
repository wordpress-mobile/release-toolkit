module Fastlane
  module Actions
    class AndroidGetAppVersionAction < Action
      def self.run(params)
        return unless UI.confirm("#{deprecated_notes} Would you like to continue with the action?")

        require_relative '../../helper/android/android_version_helper'
        Fastlane::Helper::Android::VersionHelper.get_public_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        '(DEPRECATED) Gets the public version of the app'
      end

      def self.details
        '(DEPRECATED) Gets the public version of the app'
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

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        'This action is deprecated. Please use the `version` action to retrieve version numbers.'
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
