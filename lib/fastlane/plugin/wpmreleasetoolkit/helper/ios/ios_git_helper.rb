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
        #  - The `fastlane/Deliverfile` file (which contains the `app_version` line)
        #  - The `<ProjectRoot>/<ProjectName>/Resources/AppStoreStrings.pot` file, containing a key for that version's release notes
        #
        # @env PROJECT_ROOT_FOLDER The path to the git root of the project
        # @env PROJECT_NAME The name of the directory containing the project code (especially containing the Resources/ subfolder)
        #
        # @param [Bool] include_deliverfile If true (the default), includes the `fastlane/Deliverfile` in files being commited
        # @param [Bool] include_metadata If true (the default), includes the `fastlane/download_metadata.swift` file and the `.pot` file (which typically contains an entry or release notes for the new version)
        #
        def self.commit_version_bump(include_deliverfile: true, include_metadata: true)
          files_list = [File.join(ENV['PROJECT_ROOT_FOLDER'], 'config', '.')]
          files_list.append File.join('fastlane', 'Deliverfile') if include_deliverfile
          if include_metadata
            files_list.append File.join('fastlane', 'download_metadata.swift')
            files_list.append File.join(ENV['PROJECT_ROOT_FOLDER'], ENV['PROJECT_NAME'], 'Resources', ENV['APP_STORE_STRINGS_FILE_NAME'])
          end

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
