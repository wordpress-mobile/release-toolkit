module Fastlane
  module Actions
    module SharedValues
      ANDROID_FINALIZE_PRECHECKS_CUSTOM_VALUE = :ANDROID_FINALIZE_PRECHECKS_CUSTOM_VALUE
    end

    class AndroidFinalizePrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'
        require_relative '../../helper/git_helper'

        current_branch = Fastlane::Helper::GitHelper.current_git_branch
        UI.user_error!("Current branch - '#{current_branch}' - is not a release branch. Abort.") unless current_branch.start_with?('release/')

        project_root_folder = params[:project_root_folder]
        project_name = params[:project_name]
        build_gradle_path = params[:build_gradle_path] || (File.join(project_root_folder || '.', project_name, 'build.gradle') unless project_name.nil?)
        version_properties_path = params[:version_properties_path] || File.join(project_root_folder || '.', 'version.properties')

        version = Fastlane::Helper::Android::VersionHelper.get_public_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path
        )
        message = "Finalizing release: #{version}\n"
        if params[:skip_confirm]
          UI.message(message)
        else
          UI.user_error!('Aborted by user request') unless UI.confirm("#{message}Do you want to continue?")
        end

        # Check local repo status
        other_action.ensure_git_status_clean

        version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs some prechecks before finalizing a release'
      end

      def self.details
        'Runs some prechecks before finalizing a release'
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_ANDROID_FINALIZE_PRECHECKS_SKIPCONFIRM',
                                       description: 'Skips confirmation',
                                       type: Boolean,
                                       default_value: false), # the default value if the user didn't provide one
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
        'The current app version'
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
