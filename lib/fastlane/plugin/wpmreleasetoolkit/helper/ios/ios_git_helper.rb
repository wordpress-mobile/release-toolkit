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

        # Call the `Scripts/update-translations.rb` then the `fastlane/download_metadata` Scripts from the host project folder
        #
        # @env PROJECT_ROOT_FOLDER The path to the git root of the project
        # @env PROJECT_NAME The name of the directory containing the project code (especially containing the `build.gradle` file)
        #
        # @todo Migrate the scripts, currently in each host repo and called by this method, to be helpers and actions
        #       in the release-toolkit instead, and move this code away from `ios_git_helper`.
        #
        def self.update_metadata
          Action.sh("cd #{get_from_env!(key: 'PROJECT_ROOT_FOLDER')} && ./Scripts/update-translations.rb")

          Fastlane::Helper::GitHelper.commit(message: 'Update translations', files: strings_files, push: false)

          Action.sh('cd fastlane && ./download_metadata.swift')

          Fastlane::Helper::GitHelper.commit(message: 'Update metadata translations', files: './fastlane/metadata/', push: true)
        end

        def self.strings_files
          project_root = get_from_env!(key: 'PROJECT_ROOT_FOLDER')
          project_name = get_from_env!(key: 'PROJECT_NAME')

          Dir.glob(File.join(project_root, project_name, '**', '*.strings'))
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
