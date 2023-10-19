module Fastlane
  module Helper
    # A helper class to store deprecated methods and actions
    class Deprecated
      # Creates a project_root_folder Fastlane ConfigItem
      #
      # @return [FastlaneCore::ConfigItem] The Fastlane ConfigItem for the `PROJECT_ROOT_FOLDER` environment variable
      #
      def self.project_root_folder_config_item
        UI.deprecated('DEPRECATED: The PROJECT_ROOT_FOLDER environment variable and config item are deprecated and will be removed in a future version of the Release Toolkit. Please provide an explicit path for the `version.properties` or `build.gradle` file instead.')

        FastlaneCore::ConfigItem.new(
          key: :project_root_folder,
          env_name: 'FL_DEPRECATED_PROJECT_ROOT_FOLDER',
          description: 'The path to the project root folder',
          deprecated: true,
          optional: true,
          type: String,
          default_value: ENV['PROJECT_ROOT_FOLDER']
        )
      end
    end
  end
end
