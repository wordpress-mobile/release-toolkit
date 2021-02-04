module Fastlane
  module Helper
    module Ios
      module GitHelper
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

        def self.delete_tags(version)
          Action.sh("git tag | xargs git tag -d; git fetch --tags")
          tags = Action.sh("git tag")
          tags.split("\n").each do | tag |
            if (tag.split(".").length == 4) then
              if tag.start_with?(version) then
                UI.message("Removing: #{tag}")
                Action.sh("git tag -d #{tag}")
                Action.sh("git push origin :refs/tags/#{tag}")
              end
            end
          end
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