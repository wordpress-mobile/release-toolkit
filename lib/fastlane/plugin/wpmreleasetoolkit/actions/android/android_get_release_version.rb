module Fastlane
  module Actions
    class AndroidGetReleaseVersionAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper.rb'
        flavor = ENV['RELEASE_FLAVOR'].nil? ? params[:app] : ENV['RELEASE_FLAVOR']
        Fastlane::Helper::Android::VersionHelper.get_release_version(flavor)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gets the public version of the app'
      end

      def self.details
        'Gets the public version of the app'
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

      def self.output
        # Define the shared values you are going to provide
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
        'Return the public version of the app'
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
