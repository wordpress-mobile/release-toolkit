module Fastlane
  module Actions
    class IosValidateCiBuildAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_git_helper.rb'
        require_relative '../../helper/ios/ios_version_helper.rb'

        version = Fastlane::Helper::Ios::VersionHelper::get_public_version()
        UI.user_error!("HEAD is not on tag. Aborting!") unless Fastlane::Helper::Ios::GitHelper::is_head_on_tag()

        return Fastlane::Helper::Ios::GitHelper::has_final_tag_for(version)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Validate the build on CI environment"
      end

      def self.details
        "Validate the build on CI environment"
      end

      def self.available_options
        [

        ]
      end

      def self.output

      end

      def self.return_value
        
      end

      def self.authors
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end