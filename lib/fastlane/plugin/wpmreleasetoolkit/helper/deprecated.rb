module Fastlane
  module Helper
    # A helper class to store deprecated methods and actions
    class Deprecated
      # Creates a project_root_folder Fastlane ConfigItem
      #
      # @return [FastlaneCore::ConfigItem] The Fastlane ConfigItem for the `PROJECT_ROOT_FOLDER` environment variable
      #
      def self.project_root_folder_config_item
        verify_block = proc do
          unless ENV['PROJECT_ROOT_FOLDER'].nil?
            UI.deprecated('DEPRECATED: The PROJECT_ROOT_FOLDER environment variable and config item are deprecated and will be removed in a future version of the Release Toolkit. Please provide an explicit path for instead.')
          end
        end

        FastlaneCore::ConfigItem.new(
          key: :project_root_folder,
          env_name: 'PROJECT_ROOT_FOLDER',
          description: 'The path to the project root folder',
          deprecated: true,
          optional: true,
          verify_block: verify_block,
          type: String,
          default_value: ENV['PROJECT_ROOT_FOLDER']
        )
      end

      # Creates a project_root_folder Fastlane ConfigItem
      #
      # @return [FastlaneCore::ConfigItem] The Fastlane ConfigItem for the `PROJECT_ROOT_FOLDER` environment variable
      #
      def self.project_name_config_item
        verify_block = proc do
          unless ENV['PROJECT_NAME'].nil?
            UI.deprecated('DEPRECATED: The PROJECT_NAME environment variable and config item are deprecated and will be removed in a future version of the Release Toolkit. Please provide an explicit path instead.')
          end
        end

        FastlaneCore::ConfigItem.new(
          key: :project_name,
          env_name: 'PROJECT_NAME',
          description: 'The app project name',
          deprecated: true,
          optional: true,
          verify_block: verify_block,
          type: String,
          default_value: ENV['PROJECT_NAME']
        )
      end
    end
  end
end
