module Fastlane
  module Actions
    class AndroidBuildPrechecksAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/git_helper'

        UI.user_error!("Can't build beta and final at the same time!") if params[:final] && params[:beta]

        # Verify that the current branch is a release branch. Notice that `ensure_git_branch` expects a RegEx parameter
        ensure_git_branch(branch: '^release/') unless other_action.is_ci

        build_gradle_path = params[:build_gradle_path]
        version_properties_path = params[:version_properties_path]

        message = ''
        unless !params[:beta] && !params[:final]
          beta_version = Fastlane::Helper::Android::VersionHelper.get_release_version(
            build_gradle_path: build_gradle_path,
            version_properties_path: version_properties_path
          )
        end
        if params[:alpha]
          alpha_version = Fastlane::Helper::Android::VersionHelper.get_alpha_version(
            build_gradle_path: build_gradle_path,
            version_properties_path: version_properties_path
          )
        end

        UI.user_error!("Can't build a final release out of this branch because it's configured as a beta release!") if params[:final] && Fastlane::Helper::Android::VersionHelper.is_beta_version?(beta_version)

        message << "Building version #{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}) (for upload to Release Channel)\n" if params[:final]
        message << "Building version #{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}) (for upload to Beta Channel)\n" if params[:beta]
        message << "Building version #{alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}) (for upload to Alpha Channel)\n" if params[:alpha]

        UI.important(message)

        if !options[:skip_confirm] && !UI.confirm('Do you want to continue?')
          UI.user_error!('Aborted by user request')
        end

        # Check local repo status
        other_action.ensure_git_status_clean unless other_action.is_ci
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        'This action is deprecated and will be removed in an upcoming Release Toolkit version. Any necessary steps that are included in this precheck action should be added directly in a repo\'s Fastfile. See https://github.com/wordpress-mobile/release-toolkit/issues/576'
      end

      def self.description
        '(DEPRECATED) Runs some prechecks before the build'
      end

      def self.details
        '(DEPRECATED) Runs some prechecks before the build'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_SKIP_CONFIRM',
                                       description: 'True to avoid the system ask for confirmation',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :alpha,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_ALPHA_BUILD',
                                       description: 'True if this is for an alpha build',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :beta,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_BETA_BUILD',
                                       description: 'True if this is for a beta build',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :final,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_FINAL_BUILD',
                                       description: 'True if this is for a final build',
                                       type: Boolean,
                                       default_value: false),
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
