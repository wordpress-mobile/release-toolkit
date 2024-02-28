module Fastlane
  module Actions
    class AndroidTagBuildAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'

        build_gradle_path = params[:build_gradle_path]
        version_properties_path = params[:version_properties_path]

        release_ver = Fastlane::Helper::Android::VersionHelper.get_release_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        alpha_ver = Fastlane::Helper::Android::VersionHelper.get_alpha_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
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
                                       type: Boolean,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :build_gradle_path,
                                       description: 'Path to the build.gradle file',
                                       type: String,
                                       optional: true,
                                       conflicting_options: [:version_properties_path]),
          FastlaneCore::ConfigItem.new(key: :version_properties_path,
                                       description: 'Path to the version.properties file',
                                       type: String,
                                       optional: true,
                                       conflicting_options: [:build_gradle_path]),
        ]
      end

      def self.output
      end

      def self.return_value
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
