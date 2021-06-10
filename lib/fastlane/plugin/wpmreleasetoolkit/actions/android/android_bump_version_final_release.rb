module Fastlane
  module Actions
    class AndroidBumpVersionFinalReleaseAction < Action
      def self.run(params)
        UI.message 'Bumping app release version...'

        require_relative '../../helper/android/android_git_helper.rb'
        require_relative '../../helper/android/android_version_helper.rb'

        Fastlane::Helper::GitHelper.ensure_on_branch!('release')
        app = ENV['PROJECT_NAME'].nil? ? params[:app] : ENV['PROJECT_NAME']

        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(app)
        current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version(app)
        final_version = Fastlane::Helper::Android::VersionHelper.calc_final_release_version(current_version, current_version_alpha)


        vname = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
        vcode = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
        UI.message("Current version[#{app}]: #{current_version[vname]}(#{current_version[vcode]})")
        UI.message("Current alpha version[#{app}]: #{current_version_alpha[vname]}(#{current_version_alpha[vcode]})") unless current_version_alpha.nil?
        UI.message("New release version[#{app}]: #{final_version[vname]}(#{final_version[vcode]})")

        UI.message 'Updating version.properties...'
        Fastlane::Helper::Android::VersionHelper.update_versions(app, final_version, current_version_alpha)
        UI.message 'Done!'

        Fastlane::Helper::Android::GitHelper.commit_version_bump()
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Bumps the version of the app for a new beta'
      end

      def self.details
        'Bumps the version of the app for a new beta'
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

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
