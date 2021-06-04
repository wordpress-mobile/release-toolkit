module Fastlane
  module Actions
    class IosUpdateMetadataAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_git_helper'

        Fastlane::Helper::Ios::GitHelper.update_metadata()
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Downloads translated metadata from the translation system'
      end

      def self.details
        'Downloads translated metadata from the translation system'
      end

      def self.available_options
      end

      def self.output
      end

      def self.return_value
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
