module Fastlane
  module Actions
    class AndroidBumpVersionFinalReleaseAction < Action
      def self.run(params)
        UI.message 'Bumping app release version...'

        require_relative '../../helper/android/android_git_helper.rb'
        require_relative '../../helper/android/android_version_helper.rb'

        Fastlane::Helper::GitHelper.ensure_on_branch!('release')
        @flavor = params[:app]
        create_config()
        show_config()

        UI.message 'Updating gradle.properties...'
        Fastlane::Helper::Android::VersionHelper.update_versions(@flavor, @final_version, @current_version_alpha)
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
                                       env_name: 'APP',
                                       description: 'The app to get the release version for',
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       default_value: 'wordpress'), # the default value if the user didn't provide one
        ]
      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end

      private

      def self.create_config
        @current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(@flavor)
        @current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version(@flavor)
        @final_version = Fastlane::Helper::Android::VersionHelper.calc_final_release_version(@current_version, @current_version_alpha)
      end

      def self.show_config
        vname = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
        vcode = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
        UI.message("Current version[#{@flavor}]: #{@current_version[vname]}(#{@current_version[vcode]})")
        UI.message("Current alpha version[#{@flavor}]: #{@current_version_alpha[vname]}(#{@current_version_alpha[vcode]})") unless @current_version_alpha.nil?
        UI.message("New release version[#{@flavor}]: #{@final_version[vname]}(#{@final_version[vcode]})")
      end
    end
  end
end
