module Fastlane
  module Actions
    module SharedValues
      ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE = :ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE
    end

    class AndroidCurrentBranchIsHotfixAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'

        version_properties_path = params[:version_properties_path]

        version = Fastlane::Helper::Android::VersionHelper.get_release_version(
          version_properties_path: version_properties_path
        )
        Fastlane::Helper::Android::VersionHelper.is_hotfix?(version)
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
        [
          FastlaneCore::ConfigItem.new(key: :version_properties_path,
                                       description: 'Path to the version.properties file',
                                       type: String,
                                       optional: false),
        ]
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
        platform == :android
      end
    end
  end
end
