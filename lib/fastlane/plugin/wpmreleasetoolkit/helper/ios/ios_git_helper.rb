module Fastlane
  module Helper
    module Ios
      # Helper methods to execute git-related operations that are specific to iOS projects
      #
      module GitHelper
        # Commit the files that are modified when we bump version numbers on an iOS project
        #
        # This typically commits:
        #  - The files in `./config/*` – especially `Version.*.xcconfig` files
        #  - The `fastlane/Deliverfile` file (which contains the `app_version` line)
        #
        # @env PROJECT_ROOT_FOLDER The path to the git root of the project
        #
        # @param [Bool] include_deliverfile If true (the default), includes the `fastlane/Deliverfile` in files being commited
        #
        def self.commit_version_bump(include_deliverfile: true)
          files_list = [File.join(get_from_env!(key: 'PROJECT_ROOT_FOLDER'), 'config', '.')]
          files_list.append File.join('fastlane', 'Deliverfile') if include_deliverfile

          Fastlane::Helper::GitHelper.commit(message: 'Bump version number', files: files_list)
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
