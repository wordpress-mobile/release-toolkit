module Fastlane
  module Actions
    class AndroidBumpVersionReleaseAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message 'Bumping app release version...'

        require_relative '../../helper/android/android_version_helper.rb'
        require_relative '../../helper/android/android_git_helper.rb'

        other_action.ensure_git_branch(branch: 'develop')

        # Create new configuration
        app = ENV['PROJECT_NAME'].nil? ? params[:app] : ENV['PROJECT_NAME']
        new_short_version = Fastlane::Helper::Android::VersionHelper.bump_version_release(app)

        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(app)
        current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version(app)
        new_version_beta = Fastlane::Helper::Android::VersionHelper.calc_next_release_version(current_version, current_version_alpha)
        new_version_alpha = current_version_alpha.nil? ? nil : Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(new_version_beta, current_version_alpha)
        new_release_branch = "release/#{new_short_version}"

        vname = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
        vcode = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
        UI.message("Current version[#{app}]: #{current_version[vname]}(#{current_version[vcode]})")
        UI.message("Current alpha version[#{app}]: #{current_version_alpha[vname]}(#{current_version_alpha[vcode]})") unless current_version_alpha.nil?
        UI.message("New beta version[#{app}]: #{new_version_beta[vname]}(#{new_version_beta[vcode]})")
        UI.message("New alpha version[#{app}]: #{new_version_alpha[vname]}(#{new_version_alpha[vcode]})") unless current_version_alpha.nil?
        UI.message("New version[#{app}]: #{new_short_version}")
        UI.message("Release branch: #{new_release_branch}")

        # Update local develop and branch
        UI.message 'Creating new branch...'
        Fastlane::Helper::GitHelper.create_branch(new_release_branch, from: 'develop')
        UI.message 'Done!'

        UI.message 'Updating versions...'
        Fastlane::Helper::Android::VersionHelper.update_versions(app, new_version_beta, new_version_alpha)
        Fastlane::Helper::Android::GitHelper.commit_version_bump()
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
        # Define all options your action supports.
        [
          FastlaneCore::ConfigItem.new(key: :app,
                                       env_name: 'PROJECT_NAME',
                                       description: 'The name of the app to get the release version for',
                                       is_string: true), # true: verifies the input is a string, false: every kind of value
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
