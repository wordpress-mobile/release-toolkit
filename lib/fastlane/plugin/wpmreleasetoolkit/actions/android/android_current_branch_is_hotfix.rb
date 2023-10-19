module Fastlane
  module Actions
    module SharedValues
      ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE = :ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE
    end

    class AndroidCurrentBranchIsHotfixAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'
        version = Fastlane::Helper::Android::VersionHelper.get_release_version(
          params[:build_gradle_path],
          params[:version_properties_path]
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
          FastlaneCore::ConfigItem.new(key: :build_gradle_path,
                                       description: 'Path to the build.gradle file',
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :version_properties_path,
                                       description: 'Path to the version.properties file',
                                       type: String,
                                       optional: true),
          Fastlane::Helper::Deprecated.project_root_folder_config_item,
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
