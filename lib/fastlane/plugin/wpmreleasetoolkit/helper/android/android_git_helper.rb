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

        def self.commit_version_bump()
          Fastlane::Helper::GitHelper.commit(
            message: "Bump version number",
            files: File.join(ENV["PROJECT_ROOT_FOLDER"], ENV["PROJECT_NAME"], "build.gradle"),
            push: true
          )
        end
      end
    end
  end
end