module Fastlane
  module Helper
    module Ios
      module GitHelper
        def self.bump_version_release(skip_deliver=false, skip_metadata=false)
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git add ./config/.")
          Action.sh("git add fastlane/Deliverfile") unless skip_deliver
          Action.sh("git add fastlane/download_metadata.swift") unless skip_metadata
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/Resources/#{ENV["APP_STORE_STRINGS_FILE_NAME"]}") unless skip_metadata
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push origin HEAD")
        end

        def self.bump_version_hotfix(version)
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git add ./config/.")
          Action.sh("git add fastlane/Deliverfile")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push origin HEAD")
        end

        def self.bump_version_beta()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git add ./config/.")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push origin HEAD")
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

        def self.final_tag(version)
          Action.sh("git tag #{version}")
          Action.sh("git push origin #{version}")
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

        def self.tag_build(itc_version, internal_version)
          Fastlane::Helper::GitHelper.create_tag(itc_version)
          Fastlane::Helper::GitHelper.create_tag(internal_version) unless internal_version.nil?
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

        def self.do_release_branch(branch_name)
          if (check_branch_exists(branch_name) == true) then
            UI.message("Branch #{branch_name} already exists. Skipping creation.")
            Action.sh("git checkout #{branch_name}")
            Action.sh("git pull origin #{branch_name}")
          else
            Action.sh("git checkout -b #{branch_name}")

            # Push to origin
            Action.sh("git push -u origin #{branch_name}")
          end
        end

        def self.check_branch_exists(branch_name)
          !Action.sh("git branch --list #{branch_name}").empty?
        end

        def self.check_on_branch(branch_name)
          current_branch_name=Action.sh("git symbolic-ref -q HEAD")
          UI.user_error!("This command works only on #{branch_name} branch") unless current_branch_name.include?(branch_name)
        end

        def self.is_head_on_tag()
          !Action.sh("git tag --points-at HEAD").empty?
        end

        def self.has_final_tag_for(version)
          head_tags=Action.sh("git tag --points-at HEAD").split("\n")
          head_tags.each { | vtag |
            if (vtag == version)
              return true
            end
          }
          return false
        end
      end
    end
  end
end