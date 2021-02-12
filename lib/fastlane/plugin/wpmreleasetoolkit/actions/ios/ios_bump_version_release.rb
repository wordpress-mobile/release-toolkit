module Fastlane
  module Actions
    class IosBumpVersionReleaseAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message 'Bumping app release version...'

        require_relative '../../helper/ios/ios_version_helper.rb'
        require_relative '../../helper/ios/ios_git_helper.rb'

        other_action.ensure_git_branch(branch: 'develop')

        # Create new configuration
        @new_version = Fastlane::Helper::Ios::VersionHelper.bump_version_release()
        create_config()
        show_config()

        # Update local develop and branch
        Fastlane::Helper::GitHelper.checkout_and_pull('develop')
        Fastlane::Helper::GitHelper.create_branch(@new_release_branch, from: 'develop')
        UI.message 'Done!'

        UI.message 'Updating glotPressKeys...'  unless params[:skip_glotpress]
        update_glotpress_key unless params [:skip_glotpress]
        UI.message 'Done' unless params [:skip_glotpress]

        UI.message 'Updating Fastlane deliver file...' unless params[:skip_deliver]
        Fastlane::Helper::Ios::VersionHelper.update_fastlane_deliver(@new_short_version) unless params[:skip_deliver]
        UI.message 'Done!' unless params [:skip_deliver]

        UI.message 'Updating XcConfig...'
        Fastlane::Helper::Ios::VersionHelper.update_xc_configs(@new_version, @new_short_version, @new_version_internal)
        UI.message 'Done!'

        Fastlane::Helper::Ios::GitHelper.commit_version_bump(
          include_deliverfile: !params[:skip_deliver],
          include_metadata: !params[:skip_glotpress]
        )

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Bumps the version of the app and creates the new release branch'
      end

      def self.details
        'Bumps the version of the app and creates the new release branch'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_glotpress,
                                       env_name: 'FL_IOS_CODEFREEZE_BUMP_SKIPGLOTPRESS',
                                       description: 'Skips GlotPress key update',
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :skip_deliver,
                                       env_name: 'FL_IOS_CODEFREEZE_BUMP_SKIPDELIVER',
                                       description: 'Skips Deliver key update',
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one

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
        platform == :ios
      end

      private
      def self.create_config()
        @current_version = Fastlane::Helper::Ios::VersionHelper.get_build_version()
        @current_version_internal = Fastlane::Helper::Ios::VersionHelper.get_internal_version() unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_version_internal = Fastlane::Helper::Ios::VersionHelper.create_internal_version(@new_version) unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_short_version = Fastlane::Helper::Ios::VersionHelper.get_short_version_string(@new_version)
        @new_release_branch = "release/#{@new_short_version}"
      end

      def self.show_config()
        UI.message("Current build version: #{@current_version}")
        UI.message("Current internal version: #{@current_version_internal}") unless ENV['INTERNAL_CONFIG_FILE'].nil?
        UI.message("New build version: #{@new_version}")
        UI.message("New internal version: #{@new_version_internal}") unless ENV['INTERNAL_CONFIG_FILE'].nil?
        UI.message("New short version: #{@new_short_version}")
        UI.message("Release branch: #{@new_release_branch}")
      end

      def self.update_glotpress_key()
        dm_file = ENV['DOWNLOAD_METADATA']
        if (File.exist?(dm_file)) then
          sh("sed -i '' \"s/let glotPressWhatsNewKey.*/let glotPressWhatsNewKey = \\\"v#{@new_short_version}-whats-new\\\"/\" #{dm_file}")
        else
          UI.user_error!("Can't find #{dm_file}.")
        end
      end
    end
  end
end
