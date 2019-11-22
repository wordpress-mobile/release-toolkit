require_relative '../../helper/filesystem_helper'

module Fastlane
    module Actions
      class AndroidCheckEnStringsAction < Action
        def self.run(params)
          # check local repo status
          other_action.ensure_git_status_clean(show_uncommitted_changes:true)

          # set up test by removing localized strings.xml
          deleted_files = Fastlane::Helper::FilesystemHelper::delete_files("#{params[:res_dir]}/values-??/strings.xml", false)
          deleted_files += Fastlane::Helper::FilesystemHelper::delete_files("#{params[:res_dir]}/values-??-r??/strings.xml", false)

          if (deleted_files.count > 0)
            plural = ""
            if (deleted_files.count > 1)
              plural = "s"
            end
            UI.message("#{deleted_files.count} localized string#{plural} have been temporarily deleted to set up for the test build.")
          else
            UI.error("No localized strings have been found for deletion. Results may be invalid. Please double check that the provided res directory (#{params[:res_dir]}) is correct.")
          end

          # check for missing strings by doing a build
          UI.message("Checking for missing English strings in #{params[:res_dir]}/values/strings.xml")
          UI.message("Running test build without localized strings, this may take a while...")

          success = true
          begin
            run_gradle(params[:gradlew_path], params[:project_dir], "build")
          rescue StandardError => msg
            success = false
          end

          # clean build
          run_gradle(params[:gradlew_path], params[:project_dir], "clean")
          other_action.reset_git_repo(force: true, skip_clean: true)
          "Cleanup complete: build cleaned, localized strings are no longer deleted"
          if (not success)
            UI.user_error!("Check Failed: some English strings were missing in #{params[:res_dir]}/values/strings.xml")
          end

          "Check Success: no missing English strings found in #{params[:res_dir]}/values/strings.xml"
        end

        def self.run_gradle(gradlew_path, project_dir, task)
            return other_action.gradle(
              gradle_path: gradlew_path,
              project_dir: project_dir,
              task: task,
              print_command: false,
              print_command_output: false
            )
        end

        #####################################################
        # @!group Documentation
        #####################################################
    
        def self.description
          "checks values/strings.xml for missing strings (slow)"
        end
    
        def self.details
          "checks values/strings.xml in the specified res directory for missing strings. very slow and requires clean git status."
        end

        def self.available_options
          [
            FastlaneCore::ConfigItem.new(key: :res_dir,
                                         env_name: "FL_ANDROID_RES_DIR", 
                                         description: "specify res directory for values/strings.xml", 
                                         is_string: true,
                                         default_value: ""),
            FastlaneCore::ConfigItem.new(key: :gradlew_path,
                                         env_name: "FL_ANDROID_GRADLEW_PATH", 
                                         description: "specify gradlew file path", 
                                         is_string: true,
                                         default_value: "gradlew"),
            FastlaneCore::ConfigItem.new(key: :project_dir,
                                         env_name: "FL_ANDROID_PROJECT_DIR", 
                                         description: "specify project directory", 
                                         is_string: true,
                                         default_value: "")
          ]
        end

        def self.output
            
        end

        def self.return_value
            
        end

        def self.authors
          ["ravenstewart"]
        end

        def self.is_supported?(platform)
          platform == :android
        end

      end
    end
  end