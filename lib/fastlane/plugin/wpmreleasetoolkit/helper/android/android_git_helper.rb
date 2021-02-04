module Fastlane
  module Helper
    module Android
      module GitHelper
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

        def self.update_metadata(validate_translation_command)
          Action.sh("./tools/update-translations.sh")
          Action.sh("git submodule update --init --recursive")
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

        def self.check_on_branch(branch_name)
          current_branch_name=Action.sh("git symbolic-ref -q HEAD")
          UI.user_error!("This command works only on #{branch_name} branch") unless current_branch_name.include?(branch_name)
        end
      end
    end
  end
end