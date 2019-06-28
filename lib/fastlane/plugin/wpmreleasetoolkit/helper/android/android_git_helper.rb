module Fastlane
    module Helpers
      module AndroidGitHelper
       
        def self.git_checkout_and_pull(branch)
          Action.sh("git checkout #{branch}")
          Action.sh("git pull")
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
          Action.sh("git commit -m \"Update release notes.\"")
          Action.sh("git push")
        end
  
        def self.update_metadata(validate_translation_command)
          Action.sh("./tools/update-translations.sh")
          Action.sh("./gradlew #{validate_translation_command}")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/src/main/res")
          Action.sh("git commit -m \"Updates translations\"")
  
          Action.sh("git push")
        end

        def self.bump_version_release()
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]} && git add ./build.gradle")
          Action.sh("git commit -m \"Bump version number\"")
          Action.sh("git push")
        end

        def self.tag_build(release_version, alpha_version)
          tag_and_push(release_version)
          tag_and_push(alpha_version) unless alpha_version.nil?
        end

        private
        def self.tag_and_push(version)
          Action.sh("cd #{ENV["PROJECT_ROOT_FOLDER"]} && git tag #{version} && git push origin #{version}") 
        end
      end
    end
  end