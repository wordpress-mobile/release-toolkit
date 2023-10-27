module Fastlane
  module Helper
    # A helper class to store deprecated methods and actions
    class Deprecated
      # Creates a has_alpha_version Fastlane ConfigItem
      #
      # @return [FastlaneCore::ConfigItem] The Fastlane ConfigItem for the `HAS_ALPHA_VERSION` environment variable
      #
      def self.has_alpha_version_config_item
        verify_block = proc do
          UI.deprecated('DEPRECATED: The HAS_ALPHA_VERSION environment variable and config item are deprecated and will be removed in a future version of the Release Toolkit.')
        end

        FastlaneCore::ConfigItem.new(
          key: :has_alpha_version,
          env_name: 'HAS_ALPHA_VERSION',
          description: 'A boolean for whether there is an alpha version of the app or not',
          deprecated: true,
          optional: true,
          verify_block: verify_block,
          type: Boolean
        )
      end

      # Creates a project_root_folder Fastlane ConfigItem
      #
      # @return [FastlaneCore::ConfigItem] The Fastlane ConfigItem for the `PROJECT_ROOT_FOLDER` environment variable
      #
      def self.project_root_folder_config_item
        verify_block = proc do
          UI.deprecated('DEPRECATED: The PROJECT_ROOT_FOLDER environment variable and config item are deprecated and will be removed in a future version of the Release Toolkit. Please provide a full path instead.')
        end

        FastlaneCore::ConfigItem.new(
          key: :project_root_folder,
          env_name: 'PROJECT_ROOT_FOLDER',
          description: 'The path to the project root folder',
          deprecated: true,
          optional: true,
          verify_block: verify_block,
          type: String
        )
      end

      # Creates a project_root_folder Fastlane ConfigItem
      #
      # @return [FastlaneCore::ConfigItem] The Fastlane ConfigItem for the `PROJECT_ROOT_FOLDER` environment variable
      #
      def self.project_name_config_item
        verify_block = proc do
          UI.deprecated('DEPRECATED: The PROJECT_NAME environment variable and config item are deprecated and will be removed in a future version of the Release Toolkit. Please provide a full path instead.')
        end

        FastlaneCore::ConfigItem.new(
          key: :project_name,
          env_name: 'PROJECT_NAME',
          description: 'The app project name',
          deprecated: true,
          optional: true,
          verify_block: verify_block,
          type: String
        )
      end
    end
  end
end
