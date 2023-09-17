module Fastlane
  module Actions
    class IosCurrentBranchIsHotfixAction < Action
      def self.run(params)
        return unless UI.confirm("#{deprecated_notes} Would you like to continue with the action?")

        require_relative '../../helper/ios/ios_version_helper'
        Fastlane::Helper::Ios::VersionHelper.is_hotfix?(Fastlane::Helper::Ios::VersionHelper.get_public_version)
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
        [:ios, :mac].include?(platform)
      end
    end
  end
end
