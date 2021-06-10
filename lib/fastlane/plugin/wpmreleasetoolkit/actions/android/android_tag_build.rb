module Fastlane
  module Actions
    class AndroidTagBuildAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper.rb'
        require_relative '../../helper/android/android_git_helper.rb'

        app = ENV['PROJECT_NAME'].nil? ? params[:app] : ENV['PROJECT_NAME']

        release_ver = Fastlane::Helper::Android::VersionHelper.get_release_version(app)
        alpha_ver = Fastlane::Helper::Android::VersionHelper.get_alpha_version(app)
        Fastlane::Helper::GitHelper.create_tag(release_ver[Fastlane::Helper::Android::VersionHelper::VERSION_NAME])
        Fastlane::Helper::GitHelper.create_tag(alpha_ver[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]) unless alpha_ver.nil? || (params[:tag_alpha] == false)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Tags the current build'
      end

      def self.details
        'Tags the current build'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :tag_alpha,
                                       env_name: 'FL_ANDROID_TAG_BUILD_ALPHA',
                                       description: 'True to skip tagging the alpha version',
                                       is_string: false,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :app,
                                       env_name: 'PROJECT_NAME',
                                       description: 'The name of the app to get the release version for',
                                       is_string: true), # true: verifies the input is a string, false: every kind of value
        ]
      end

      def self.output
      end

      def self.return_value
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
