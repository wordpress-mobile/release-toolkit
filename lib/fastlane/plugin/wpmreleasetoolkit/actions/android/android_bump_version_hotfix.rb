module Fastlane
  module Actions
    class AndroidBumpVersionHotfixAction < Action
      def self.run(params)
        UI.message 'Bumping app release version for hotfix...'

        require_relative '../../helper/android/android_git_helper'

        project_root_folder = params[:project_root_folder]
        project_name = params[:project_name]
        build_gradle_path = params[:build_gradle_path] || (File.join(project_root_folder || '.', project_name, 'build.gradle') unless project_name.nil?)
        version_properties_path = params[:version_properties_path] || File.join(project_root_folder || '.', 'version.properties')

        Fastlane::Helper::GitHelper.create_branch("release/#{params[:version_name]}", from: params[:previous_version_name])

        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        new_version = Fastlane::Helper::Android::VersionHelper.calc_next_hotfix_version(params[:version_name], params[:version_code]) # NOTE: this just puts the name/code values in a tuple, unchanged (no actual calc/bumping)
        new_release_branch = "release/#{params[:version_name]}"

        name_key = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
        code_key = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
        UI.message("Current version: #{current_version[name_key]} (#{current_version[code_key]})")
        UI.message("New hotfix version: #{new_version[name_key]} (#{new_version[code_key]})")
        UI.message("Release branch: #{new_release_branch}")

        UI.message 'Updating app version...'
        Fastlane::Helper::Android::VersionHelper.update_versions(
          new_version,
          nil,
          version_properties_path: version_properties_path
        )
        UI.message 'Done!'

        Fastlane::Helper::Android::GitHelper.commit_version_bump(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Bumps the version of the app for a new beta.'
      end

      def self.details
        'Bumps the version of the app for a new beta.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_VERSION',
                                       description: 'The version name for the hotfix',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :version_code,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_CODE',
                                       description: 'The version code for the hotfix',
                                       type: Integer),
          FastlaneCore::ConfigItem.new(key: :previous_version_name,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_PREVIOUS_VERSION',
                                       description: 'The version to branch from',
                                       type: String),
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

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
