module Fastlane
  module Helper
    module Android
      # Helper methods to execute git-related operations that are specific to Android projects
      #
      module GitHelper
        # Commit the files that are modified when we bump version numbers on an Android project
        #
        # This typically commits the `version.properties` inside root folder or `build.gradle` file
        # inside the project subfolder.
        #
        # @env PROJECT_ROOT_FOLDER The path to the git root of the project
        # @env PROJECT_NAME The name of the directory containing the project code (especially containing the `build.gradle` file)
        #
        def self.commit_version_bump(build_gradle_path = nil, version_properties_path = nil)
          require_relative './android_version_helper'

          version_properties = Fastlane::Helper::Android::VersionHelper.version_properties_file(version_properties_path)
          build_gradle = Fastlane::Helper::Android::VersionHelper.gradle_path(build_gradle_path)

          if File.exist?(version_properties)
            Fastlane::Helper::GitHelper.commit(
              message: 'Bump version number',
              files: version_properties
            )
          else
            Fastlane::Helper::GitHelper.commit(
              message: 'Bump version number',
              files: build_gradle
            )
          end
        end
      end
    end
  end
end
