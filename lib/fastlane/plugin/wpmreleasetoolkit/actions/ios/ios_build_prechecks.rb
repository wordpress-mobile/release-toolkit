module Fastlane
  module Actions
    class IosBuildPrechecksAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper'

        message = ''
        message << "Building version #{Fastlane::Helper::Ios::VersionHelper.get_internal_version} and uploading to App Center\n" if params[:internal]
        message << "Building version #{Fastlane::Helper::Ios::VersionHelper.get_build_version} and uploading to App Center\n" if params[:internal_on_single_version]
        message << "Building version #{Fastlane::Helper::Ios::VersionHelper.get_build_version} and uploading to TestFlight\n" if params[:external]

        if params[:skip_confirm]
          UI.message(message)
        else
          UI.user_error!('Aborted by user request') unless UI.confirm("#{message}Do you want to continue?")
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
        'Runs some prechecks before the build'
      end

      def self.details
        'Runs some prechecks before the build'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_IOS_BUILD_PRECHECKS_SKIP_CONFIRM',
                                       description: 'True to avoid the system ask for confirmation',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :internal,
                                       env_name: 'FL_IOS_BUILD_PRECHECKS_INTERNAL_BUILD',
                                       description: 'True if this is for an internal build',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :external,
                                       env_name: 'FL_IOS_BUILD_PRECHECKS_EXTERNAL_BUILD',
                                       description: 'True if this is for a public build',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :internal_on_single_version,
                                       env_name: 'FL_IOS_BUILD_PRECHECKS_INTERNAL_SV_BUILD',
                                       description: 'True if this is for an internal build that follows the same versioning of the external',
                                       type: Boolean,
                                       default_value: false),
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
        %i[ios mac].include?(platform)
      end
    end
  end
end
