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
        def self.commit_version_bump(build_gradle_path:, version_properties_path:)
          if version_properties_path.nil? == false && File.exist?(version_properties_path)
            git_commit(
              path: version_properties_path,
              message: 'Bump version number'
            )
          elsif build_gradle_path.nil? == false && File.exist?(build_gradle_path)
            git_commit(
              path: build_gradle_path,
              message: 'Bump version number'
            )
          else
            UI.user_error!('Both version.properties and build.gradle paths where either nil or invalid.')
          end
        end
      end
    end
  end
end
