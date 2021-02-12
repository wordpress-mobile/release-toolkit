module Fastlane
  module Helper
    module Android
      # Helper methods to execute git-related operations that are specific to Android projects
      #
      module GitHelper
        # Commit and push the files that are modified when we bump version numbers on an iOS project
        #
        # This typically commits and pushes the `build.gradle` file inside the project subfolder.
        #
        # @env PROJECT_ROOT_FOLDER The path to the git root of the project
        # @env PROJECT_NAME The name of the directory containing the project code (especially containing the `build.gradle` file)
        #
        def self.commit_version_bump()
          Fastlane::Helper::GitHelper.commit(
            message: 'Bump version number',
            files: File.join(ENV['PROJECT_ROOT_FOLDER'], ENV['PROJECT_NAME'], 'build.gradle'),
            push: true
          )
        end

        # Calls the `tools/update-translations.sh` script from the project repo, then lint them using the provided gradle task
        #
        # @env PROJECT_ROOT_FOLDER The path to the git root of the project
        # @env PROJECT_NAME The name of the directory containing the project code (especially containing the `build.gradle` file)
        #
        # @param [String] validate_translation_command The name of the gradle task to run to validate the translations
        #
        # @todo Migrate the scripts, currently in each host repo and called by this method, to be helpers and actions
        #       in the release-toolkit instead, and move this code away from `ios_git_helper`.
        #
        def self.update_metadata(validate_translation_command)
          Action.sh('./tools/update-translations.sh')
          Action.sh('git', 'submodule', 'update', '--init', '--recursive')
          Action.sh('./gradlew', validate_translation_command)

          res_dir = File.join(ENV['PROJECT_ROOT_FOLDER'], ENV['PROJECT_NAME'], 'src', 'main', 'res')
          Fastlane::Helper::GitHelper.commit(message: 'Update translations', files: res_dir, push: true)
        end
      end
    end
  end
end
