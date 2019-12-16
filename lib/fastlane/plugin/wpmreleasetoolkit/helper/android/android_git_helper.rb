module Fastlane
    module Helpers
      module AndroidGitHelper
       
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

        def self.update_release_notes(new_version)
          Action.sh("cp #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.bak")
          Action.sh("echo \"#{new_version}\n-----\n \" > #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt")
          Action.sh("cat #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.bak >> #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt")
          Action.sh("git diff-index --quiet HEAD || git commit -m \"Update release notes.\"")
          Action.sh("git push origin HEAD")
        end
  
        def self.update_metadata(validate_translation_command)
          Action.sh("./tools/update-translations.sh")
          Action.sh("./gradlew #{validate_translation_command}")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/src/main/res")
          Action.sh("git diff-index --quiet HEAD || git commit -m \"Updates translations\"")
  
          Action.sh("git push origin HEAD")
        end

        def self.bump_version_release()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]} && git add ./build.gradle")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push origin HEAD")
        end

        def self.bump_version_beta()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]} && git add ./build.gradle")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push origin HEAD")
        end

        def self.bump_version_hotfix(version)
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]} && git add ./build.gradle")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push origin HEAD")
        end
        
        def self.bump_version_final()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]} && git add ./build.gradle")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push origin HEAD")
        end

        def self.tag_build(release_version, alpha_version)
          tag_and_push(release_version)
          tag_and_push(alpha_version) unless alpha_version.nil?
        end

        def self.check_on_branch(branch_name) 
          current_branch_name=Action.sh("git symbolic-ref -q HEAD")
          UI.user_error!("This command works only on #{branch_name} branch") unless current_branch_name.include?(branch_name)
        end

        def self.branch_for_hotfix(tag_version, new_version)
          Action.sh("git checkout #{tag_version}")
          Action.sh("git checkout -b release/#{new_version}")
          Action.sh("git push --set-upstream origin release/#{new_version}")
        end

        private
        def self.tag_and_push(version)
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git tag #{version} && git push origin #{version}") 
        end
      end
    end
  end
