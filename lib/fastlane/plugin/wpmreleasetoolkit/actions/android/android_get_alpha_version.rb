module Fastlane
  module Actions
    class AndroidGetAlphaVersionAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'

        has_alpha_version = params[:has_alpha_version]
        project_root_folder = params[:project_root_folder]
        project_name = params[:project_name]
        build_gradle_path = params[:build_gradle_path] || (File.join(project_root_folder || '.', project_name, 'build.gradle') unless project_name.nil?)
        version_properties_path = params[:version_properties_path] || File.join(project_root_folder || '.', 'version.properties')

        Fastlane::Helper::Android::VersionHelper.get_alpha_version(
          build_gradle_path: build_gradle_path,
          version_properties_path: version_properties_path,
          has_alpha_version: has_alpha_version
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gets the alpha version of the app'
      end

      def self.details
        'Gets the alpha version of the app'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :build_gradle_path,
                                       description: 'Path to the build.gradle file',
                                       type: String,
                                       optional: true,
                                       conflicting_options: %i[project_name
                                                               project_root_folder
                                                               version_properties_path]),
          FastlaneCore::ConfigItem.new(key: :version_properties_path,
                                       description: 'Path to the version.properties file',
                                       type: String,
                                       optional: true,
                                       conflicting_options: %i[build_gradle_path
                                                               project_name
                                                               project_root_folder]),
          Fastlane::Helper::Deprecated.project_root_folder_config_item,
          Fastlane::Helper::Deprecated.project_name_config_item,
          Fastlane::Helper::Deprecated.has_alpha_version_config_item,
        ]
      end

      def self.output
        # Define the shared values you are going to provide
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
        'Return the alpha version of the app'
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
