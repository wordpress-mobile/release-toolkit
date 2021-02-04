module Fastlane
  module Helper
    module Ios
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
          files_list = [ File.join(ENV["PROJECT_ROOT_FOLDER"], "config", ".") ]
          if include_deliverfile
            files_list.append File.join("fastlane", "Deliverfile")
          end
          if include_metadata
            files_list.append File.join("fastlane", "download_metadata.swift")
            files_list.append File.join(ENV["PROJECT_ROOT_FOLDER"], ENV["PROJECT_NAME"], "Resources", ENV["APP_STORE_STRINGS_FILE_NAME"])
          end

          Fastlane::Helper::GitHelper.commit(message: "Bump version number", files: files_list, push: true)
        end

        def self.localize_project()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && ./Scripts/localize.py")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}*.lproj/*.strings")
          is_repo_clean = `git status --porcelain`.empty?
          if is_repo_clean then
            UI.message("No new strings, skipping commit")
          else
            Action.sh("git commit -m \"Updates strings for localization\"")
            Action.sh("git push origin HEAD")
          end
        end

        def self.update_metadata()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && ./Scripts/update-translations.rb")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/*.lproj/*.strings")
          Action.sh("git diff-index --quiet HEAD || git commit -m \"Updates translation\"")

          Action.sh("cd fastlane && ./download_metadata.swift")
          Action.sh("git add ./fastlane/metadata/")
          Action.sh("git diff-index --quiet HEAD || git commit -m \"Updates metadata translation\"")

          Action.sh("git push origin HEAD")
        end
      end
    end
  end
end