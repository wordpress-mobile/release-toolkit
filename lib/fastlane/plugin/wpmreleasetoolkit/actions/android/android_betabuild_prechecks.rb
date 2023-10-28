module Fastlane
  module Actions
    class AndroidBetabuildPrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"
        UI.message "Work on version: #{params[:base_version]}" unless params[:base_version].nil?

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'

        project_root_folder = params[:project_root_folder]
        project_name = params[:project_name]
        build_gradle_path = params[:build_gradle_path] || (File.join(project_root_folder || '.', project_name, 'build.gradle') unless project_name.nil?)
        version_properties_path = params[:version_properties_path] || File.join(project_root_folder || '.', 'version.properties')

        # Checkout default branch and update
        default_branch = params[:default_branch]
        Fastlane::Helper::GitHelper.checkout_and_pull(default_branch)

        # Check versions
        release_version = Fastlane::Helper::Android::VersionHelper.get_release_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        message = "The following current version has been detected: #{release_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}\n"
        alpha_release_version = Fastlane::Helper::Android::VersionHelper.get_alpha_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        message << "The following Alpha version has been detected: #{alpha_release_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}\n" unless alpha_release_version.nil?

        # Check branch
        app_version = Fastlane::Helper::Android::VersionHelper.get_public_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        UI.user_error!("#{message}Release branch for version #{app_version} doesn't exist. Abort.") unless !params[:base_version].nil? || Fastlane::Helper::GitHelper.checkout_and_pull(release: app_version)

        # Check user overwrite
        unless params[:base_version].nil?
          overwrite_version = get_user_build_version(version: params[:base_version], message: message)
          release_version = overwrite_version[0]
          alpha_release_version = overwrite_version[1]
        end

        next_beta_version = Fastlane::Helper::Android::VersionHelper.calc_next_beta_version(release_version, alpha_release_version)
        next_alpha_version = Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(next_beta_version, alpha_release_version) unless alpha_release_version.nil?

        # Verify
        message << "Updating branch to version: #{next_beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{next_beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}) "
        message << "and #{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n" unless alpha_release_version.nil?
        if params[:skip_confirm]
          UI.message(message)
        else
          UI.user_error!('Aborted by user request') unless UI.confirm("#{message}Do you want to continue?")
        end

        # Check local repo status
        other_action.ensure_git_status_clean

        # Return the current version
        [next_beta_version, next_alpha_version]
      end

      def self.get_user_build_version(version:, message:)
        UI.user_error!("Release branch for version #{version} doesn't exist. Abort.") unless Fastlane::Helper::GitHelper.checkout_and_pull(release: version)
        release_version = Fastlane::Helper::Android::VersionHelper.get_release_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        message << "Looking at branch release/#{version} as requested by user. Detected version: #{release_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}.\n"
        alpha_release_version = Fastlane::Helper::Android::VersionHelper.get_alpha_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        message << "and Alpha Version: #{alpha_release_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}\n" unless alpha_release_version.nil?
        [release_version, alpha_release_version]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs some prechecks before preparing for a new test build'
      end

      def self.details
        'Updates the relevant release branch, checks the app version and ensure the branch is clean'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :base_version,
                                       env_name: 'FL_ANDROID_BETABUILD_PRECHECKS_BASE_VERSION',
                                       description: 'The version to work on', # a short description of this parameter
                                       type: String,
                                       optional: true), # true: verifies the input is a string, false: every kind of value),
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_ANDROID_BETABUILD_PRECHECKS_SKIPCONFIRM',
                                       description: 'Skips confirmation',
                                       type: Boolean,
                                       default_value: false), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :default_branch,
                                       env_name: 'FL_RELEASE_TOOLKIT_DEFAULT_BRANCH',
                                       description: 'Default branch of the repository',
                                       type: String,
                                       default_value: Fastlane::Helper::GitHelper::DEFAULT_GIT_BRANCH),
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
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
