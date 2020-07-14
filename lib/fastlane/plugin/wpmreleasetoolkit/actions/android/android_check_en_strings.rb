require_relative '../../helper/filesystem_helper'

module Fastlane
    module Actions
      class AndroidCheckEnStringsAction < Action
        def self.run(params)
          # check local repo status
          if params[:ensure_git_status_clean] then
            other_action.ensure_git_status_clean(show_uncommitted_changes:true)
          end

          res_dir = "#{Fastlane::Helper::FilesystemHelper::project_path()}/#{params[:res_dir]}"
          # set up test by removing localized strings.xml
          deleted_files = Fastlane::Helper::FilesystemHelper::delete_files("#{res_dir}/values-??/strings.xml", true, false)
          deleted_files += Fastlane::Helper::FilesystemHelper::delete_files("#{res_dir}/values-??-r??/strings.xml", true, false)

          if (deleted_files.count > 0)
            UI.message("#{deleted_files.count} localized string " + "file".pluralize(deleted_files.count) + " temporarily deleted to set up for the test build.")
          else
            UI.error("No localized string files have been found for deletion. Results may be invalid. Please double check that the provided res directory (#{res_dir}) is correct.")
          end

          # check for missing strings by doing a build
          UI.message("Checking for missing English strings in #{res_dir}/values/strings.xml")
          UI.message("Running test build without localized strings, this may take a while...")

          success = true
          begin
            run_gradle("build", params[:verbose])
            UI.message("Test build complete.")
          rescue StandardError
            suggestion = "";
            if (not params[:verbose])
              suggestion = " (set verbose to true for more information)"
            end
            UI.error("Test build failed#{suggestion}.")
            success = false
          ensure
            # clean up
            run_gradle("clean", false)
            other_action.reset_git_repo(force: true, files: deleted_files)
            UI.message("Cleanup complete: build cleaned, localized string files are no longer deleted")
          end

          if (not success)
            UI.user_error!("Check Failed: some English strings may be missing in #{res_dir}/values/strings.xml")
          end

          UI.success "Check Success: no missing English strings found in #{res_dir}/values/strings.xml"
          "Check Success"
        end

        def self.run_gradle(task, print_output)
            return other_action.gradle(
              project_dir: "#{Fastlane::Helper::FilesystemHelper::project_path()}",
              task: task,
              print_command: false,
              print_command_output: print_output
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
            FastlaneCore::ConfigItem.new(key: :ensure_git_status_clean,
                                         env_name: "FL_ANDROID_CHECK_EN_STRINGS_ENSURE_GIT_STATUS_CLEAN", 
                                         description: "specify whether to ensure git status is clean", 
                                         is_string: false,
                                         default_value: true),
            FastlaneCore::ConfigItem.new(key: :verbose,
                                         env_name: "FL_ANDROID_CHECK_EN_STRINGS_VERBOSE", 
                                         description: "specify whether to display more output", 
                                         is_string: false,
                                         default_value: false)
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
