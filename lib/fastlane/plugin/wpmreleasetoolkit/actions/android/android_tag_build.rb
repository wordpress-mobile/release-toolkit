module Fastlane
  module Actions
    class AndroidTagBuildAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper.rb'
        require_relative '../../helper/android/android_git_helper.rb'

        release_ver = Fastlane::Helper::Android::VersionHelper.get_release_version()
        alpha_ver = Fastlane::Helper::Android::VersionHelper.get_alpha_version() unless ENV['HAS_ALPHA_VERSION'].nil?
        Fastlane::Helper::GitHelper.create_tag(release_ver[Fastlane::Helper::Android::VersionHelper::VERSION_NAME])
        Fastlane::Helper::GitHelper.create_tag(alpha_ver[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]) unless ENV['HAS_ALPHA_VERSION'].nil? || (params[:tag_alpha] == false)
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
