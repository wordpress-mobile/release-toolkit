module Fastlane
  module Helper
    module Ios
      # Helper methods to execute git-related operations that are specific to iOS projects
      #
      module GitHelper
        # Commit and push the files that are modified when we bump version numbers on an iOS project
        #
        # This typically commits and pushes:
        #  - The files in `./config/*` – especially `Version.*.xcconfig` files
        #
        # @env PROJECT_ROOT_FOLDER The path to the git root of the project
        #
        def self.commit_version_bump
          files_list = [File.join(get_from_env!(key: 'PROJECT_ROOT_FOLDER'), 'config', '.')]

          Fastlane::Helper::GitHelper.commit(message: 'Bump version number', files: files_list, push: true)
        end

        def self.get_from_env!(key:)
          ENV.fetch(key) do
            UI.user_error! "Could not find value for \"#{key}\" in environment."
          end
        end
      end
    end
  end
end
