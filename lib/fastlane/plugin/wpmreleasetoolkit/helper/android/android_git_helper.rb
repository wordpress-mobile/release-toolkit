module Fastlane
  module Helper
    module Android
      module GitHelper
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
      end
    end
  end
end