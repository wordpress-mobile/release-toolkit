module Fastlane
  module Actions
    class AndroidBuildPreflightAction < Action
      def self.run(params)

        # Validate mobile configuration secrets
        other_action.configure_apply

        # Check gems and pods are up to date. This will exit if it fails
        begin
          Action.sh("bundle check")
        rescue
          UI.user_error!("You should run 'bundle install' to make sure gems are up to date")
          raise
        end

        begin
          Action.sh("command -v bundletool > /dev/null")
        rescue
          UI.user_error!("bundletool is required to build the APKs. Install it with 'brew install bundletool'")
          raise
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Clean the environment to ensure a safe build"
      end

      def self.details
        "Clean the environment to ensure a safe build"
      end

      def self.available_options

      end

      def self.output

      end

      def self.return_value

      end

      def self.authors
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
