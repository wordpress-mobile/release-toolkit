module Fastlane
    module Helpers
      module IosGitHelper
       
        def self.git_checkout_and_pull(branch)
          Action.sh("git checkout #{branch}")
          Action.sh("git pull")
        end
  
        def self.git_checkout_and_pull_release_branch_for(version)
          branch_name = "release/#{version}"
          Action.sh("git pull")
          begin
            Action.sh("git checkout #{branch_name}")
            Action.sh("git pull origin #{branch_name}")
            return true
          rescue
            return false
          end
        end
  
        def self.branch_for_hotfix(tag_version, new_version)
          Action.sh("git checkout #{tag_version}")
          Action.sh("git checkout -b release/#{new_version}")
          Action.sh("git push --set-upstream origin release/#{new_version}")
        end
  
        def self.bump_version_release()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git add ./config/.")
          Action.sh("git add fastlane/Deliverfile")
          Action.sh("git add fastlane/download_metadata.swift")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/Resources/#{ENV["APP_STORE_STRINGS_FILE_NAME"]}")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push")
        end
  
        def self.bump_version_hotfix(version)
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git add ./config/.")
          Action.sh("git add fastlane/Deliverfile")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/Resources/#{ENV["APP_STORE_STRINGS_FILE_NAME"]}")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push")
        end
  
        def self.bump_version_beta()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git add ./config/.")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push")
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
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}*.lproj/Localizable.strings")
          Action.sh("git commit -m \"Updates strings for localization\"")
          Action.sh("git push")
        end
  
        def self.update_release_notes(new_version)
          Action.sh("cp #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/Resources/release_notes.txt ")
          Action.sh("echo \"#{new_version}\n-----\n \" > #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt")
          Action.sh("cat #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/Resources/release_notes.txt >> #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/Resources/release_notes.txt")
          Action.sh("git commit -m \"Update release notes.\"")
          Action.sh("git push")
        end
  
        def self.tag_build(itc_version, internal_version)
          tag_and_push(itc_version)
          tag_and_push(internal_version) unless internal_version.nil?
        end
  
        def self.update_metadata()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && ./Scripts/update-translations.rb")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/*.lproj/Localizable.strings")
          Action.sh("git diff-index --quiet HEAD || git commit -m \"Updates translation\"")
  
          Action.sh("cd fastlane && ./download_metadata.swift")
          Action.sh("git add ./fastlane/metadata/")
          Action.sh("git diff-index --quiet HEAD || git commit -m \"Updates metadata translation\"")
  
          Action.sh("git push")
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

        private
        def self.tag_and_push(version)
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git tag #{version} && git push origin #{version}") 
        end
      end
  end
end