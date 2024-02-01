module Fastlane
  module Actions
    class IosCurrentBranchIsHotfixAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper'
        Fastlane::Helper::Ios::VersionHelper.is_hotfix?(Fastlane::Helper::Ios::VersionHelper.get_public_version)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Checks if the current branch is for a hotfix'
      end

      def self.details
        'Checks if the current branch is for a hotfix'
      end

      def self.available_options
      end

      def self.output
      end

      def self.return_value
        'True if the branch is for a hotfix, false otherwise'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end
    end
  end
end
