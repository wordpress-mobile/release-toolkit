module Fastlane
    module Helpers
      module AndroidGitHelper
       
        def self.git_checkout_and_pull(branch)
          Action.sh("git checkout #{branch}")
          Action.sh("git pull")
        end
        
        def self.get_create_codefreeze_branch(branch, new_version)
          Action.sh("git checkout develop")
          Action.sh("git pull")
          Action.sh("git checkout -b #{branch}")
          commit_release_notes_for_code_freeze(new_version)
          Action.sh("git push --set-upstream origin #{branch}")
        end
  
        def self.commit_release_notes_for_code_freeze(new_version)
          Action.sh("cp #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/metadata/release_notes.txt")
          Action.sh("echo \"#{new_version}\n-----\n \" > #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt")
          Action.sh("cat #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/metadata/release_notes.txt >> #{ENV["PROJECT_ROOT_FOLDER"]}RELEASE-NOTES.txt")
          Action.sh("git add RELEASE-NOTES.txt #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/metadata/release_notes.txt")
          Action.sh("git commit -m \"Update release notes for code freeze\"")
        end
  
        def self.update_metadata(validate_translation_command)
          Action.sh("./tools/update-translations.sh")
          Action.sh("./gradlew #{validate_translation_command}")
          Action.sh("git add #{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/src/main/res")
          Action.sh("git commit -m \"Updates translations\"")
  
          Action.sh("git push")
        end
      end
    end
  end