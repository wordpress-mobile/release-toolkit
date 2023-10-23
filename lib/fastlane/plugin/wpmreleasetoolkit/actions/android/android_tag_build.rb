module Fastlane
  module Actions
    class AndroidTagBuildAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'

        project_root_folder = params[:project_root_folder]
        project_name = params[:project_name]
        build_gradle_path = params[:build_gradle_path] || File.join(project_root_folder || '.', project_name, 'build.gradle')
        version_properties_path = params[:version_properties_path] || File.join(project_root_folder || '.', 'version.properties')

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
                                       conflicting_options: %i[project_name
                                                               project_root_folder
                                                               version_properties_path]),
          FastlaneCore::ConfigItem.new(key: :version_properties_path,
                                       description: 'Path to the version.properties file',
                                       type: String,
                                       optional: true,
                                       conflicting_options: %i[build_gradle_path
                                                               project_name
                                                               project_root_folder]),
          Fastlane::Helper::Deprecated.project_root_folder_config_item,
          Fastlane::Helper::Deprecated.project_name_config_item,
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
