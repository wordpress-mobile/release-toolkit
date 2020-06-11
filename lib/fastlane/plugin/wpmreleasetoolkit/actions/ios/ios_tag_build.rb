module Fastlane
  module Actions
    class IosTagBuildAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper.rb'
        require_relative '../../helper/ios/ios_git_helper.rb'

        itc_ver = Fastlane::Helpers::IosVersionHelper.get_build_version()
        int_ver = Fastlane::Helpers::IosVersionHelper.get_internal_version() unless ENV["INTERNAL_CONFIG_FILE"].nil?
        Fastlane::Helpers::IosGitHelper.tag_build(itc_ver, int_ver)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Tags the current build"
      end

      def self.details
        "Tags the current build"
      end

      def self.available_options
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
