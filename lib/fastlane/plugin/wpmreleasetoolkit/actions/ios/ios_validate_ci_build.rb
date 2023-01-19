module Fastlane
  module Actions
    class IosValidateCiBuildAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_git_helper'
        require_relative '../../helper/ios/ios_version_helper'

        version = Fastlane::Helper::Ios::VersionHelper.get_public_version()
        head_tags = Fastlane::Helper::GitHelper.list_tags_on_current_commit()
        UI.user_error!('HEAD is not on tag. Aborting!') if head_tags.empty?

        return head_tags.include?(version) # Current commit is tagged with "version" tag
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Validate the build on CI environment'
      end

      def self.details
        'Validate the build on CI environment'
      end

      def self.available_options
        []
      end

      def self.output
      end

      def self.return_value
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
