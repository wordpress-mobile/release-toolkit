module Fastlane
  module Actions
    class AndroidBumpVersionBetaAction < Action
      def self.run(params)
        UI.message 'Bumping app release version...'

        require_relative '../../helper/android/android_git_helper'
        require_relative '../../helper/android/android_version_helper'

        # Verify that the current branch is a release branch. Notice that `ensure_git_branch` expects a RegEx parameter
        ensure_git_branch(branch: '^release/')

        has_alpha_version = params[:has_alpha_version]
        project_root_folder = params[:project_root_folder]
        project_name = params[:project_name]
        build_gradle_path = params[:build_gradle_path] || (File.join(project_root_folder || '.', project_name, 'build.gradle') unless project_name.nil?)
        version_properties_path = params[:version_properties_path] || File.join(project_root_folder || '.', 'version.properties')

        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path,
          has_alpha_version: has_alpha_version
        )
        current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path,
          has_alpha_version: has_alpha_version
        )
        new_version_beta = Fastlane::Helper::Android::VersionHelper.calc_next_beta_version(current_version, current_version_alpha)
        new_version_alpha = current_version_alpha.nil? ? nil : Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(new_version_beta, current_version_alpha)

        vname = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
        vcode = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
        UI.message("Current version: #{current_version[vname]}(#{current_version[vcode]})")
        UI.message("Current alpha version: #{current_version_alpha[vname]}(#{current_version_alpha[vcode]})") unless current_version_alpha.nil?
        UI.message("New beta version: #{new_version_beta[vname]}(#{new_version_beta[vcode]})")
        UI.message("New alpha version: #{new_version_alpha[vname]}(#{new_version_alpha[vcode]})") unless current_version_alpha.nil?

        UI.message 'Updating app version...'
        Fastlane::Helper::Android::VersionHelper.update_versions(
          new_version_beta,
          new_version_alpha,
          version_properties_path: version_properties_path,
          has_alpha_version: has_alpha_version
        )
        UI.message 'Done!'

        Fastlane::Helper::Android::GitHelper.commit_version_bump(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
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
          Fastlane::Helper::Deprecated.has_alpha_version_config_item,
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
