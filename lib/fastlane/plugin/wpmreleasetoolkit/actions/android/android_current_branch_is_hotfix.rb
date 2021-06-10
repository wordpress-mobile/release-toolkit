module Fastlane
  module Actions
    module SharedValues
      ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE = :ANDROID_CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE
    end

    class AndroidCurrentBranchIsHotfixAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper.rb'
        app = ENV['PROJECT_NAME'].nil? ? params[:app] : ENV['PROJECT_NAME']
        Fastlane::Helper::Android::VersionHelper.is_hotfix?(Fastlane::Helper::Android::VersionHelper.get_release_version(app))
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
        # Define all options your action supports.
        [
          FastlaneCore::ConfigItem.new(key: :app,
                                       env_name: 'PROJECT_NAME',
                                       description: 'The app to get the release version for',
                                       is_string: true), # true: verifies the input is a string, false: every kind of value
        ]
      end

      def self.output
      end

      def self.return_value
        'True if the branch is for a hotfix, false otherwise'
      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
