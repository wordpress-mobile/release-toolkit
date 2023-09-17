module Fastlane
  module Actions
    module SharedValues
      ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE = :ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE
    end

    class AndroidCurrentBranchIsHotfixAction < Action
      def self.run(params)
        return unless UI.confirm("#{deprecated_notes} Would you like to continue with the action?")

        require_relative '../../helper/android/android_version_helper'
        version = Fastlane::Helper::Android::VersionHelper.get_release_version
        Fastlane::Helper::Android::VersionHelper.is_hotfix?(version)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        '(DEPRECATED) Checks if the current branch is for a hotfix'
      end

      def self.details
        '(DEPRECATED) Checks if the current branch is for a hotfix'
      end

      def self.available_options
        # Define all options your action supports.
      end

      def self.output
      end

      def self.return_value
        'True if the branch is for a hotfix, false otherwise'
      end

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        'This action is deprecated. Please use the `current_branch_is_hotfix` action instead.'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
