module Fastlane
  module Actions
    class IosLocalizeProjectAction < Action
      def self.run(params)
        UI.message 'Updating project localisation...'

        require_relative '../../helper/ios/ios_git_helper'
        other_action.cocoapods()
        Fastlane::Helper::Ios::GitHelper.localize_project()

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gathers the string to localise'
      end

      def self.details
        'Gathers the string to localise. Deprecated in favor of the new `ios_generate_strings_file_from_code`'
      end

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        'This action is deprecated in favor of `ios_generate_strings_file_from_code`'
      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
