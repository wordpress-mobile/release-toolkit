module Fastlane
    module Actions    
      class IosBumpVersionReleaseAction < Action
        def self.run(params)
          # fastlane will take care of reading in the parameter and fetching the environment variable:
          UI.message "Bumping app release version..."

          require_relative '../../helper/ios/ios_version_helper.rb'
          require_relative '../../helper/ios/ios_git_helper.rb'
          
          other_action.ensure_git_branch(branch: "develop")

          # Create new configuration
          @new_version = Fastlane::Helpers::IosVersionHelper.bump_version_release()
          create_config()
          show_config()

          # Update local develop and branch
          Fastlane::Helpers::IosGitHelper.git_checkout_and_pull("develop")
          Fastlane::Helpers::IosGitHelper.do_release_branch(@new_release_branch)
          UI.message "Done!"

          UI.message "Updating glotPressKeys..."
          update_glotpress_key
          UI.message "Done"

          UI.message "Updating Fastlane deliver file..."
          Fastlane::Helpers::IosVersionHelper.update_fastlane_deliver(@new_short_version)
          UI.message "Done!"
          UI.message "Updating XcConfig..."
          Fastlane::Helpers::IosVersionHelper.update_xc_configs(@new_version, @new_short_version, @new_version_internal) 
          UI.message "Done!"

          Fastlane::Helpers::IosGitHelper.bump_version_release()
          
          UI.message "Done."
        end
  
        #####################################################
        # @!group Documentation
        #####################################################
  
        def self.description
          "Bumps the version of the app and creates the new release branch"
        end
  
        def self.details
          "Bumps the version of the app and creates the new release branch"
        end
  
        def self.available_options
          
        end
  
        def self.output
          
        end
  
        def self.return_value
          
        end
  
        def self.authors
          ["loremattei"]
        end
  
        def self.is_supported?(platform)
          platform == :ios
        end


        private
        def self.create_config()
          @current_version = Fastlane::Helpers::IosVersionHelper.get_build_version()
          @current_version_internal = Fastlane::Helpers::IosVersionHelper.get_internal_version() unless ENV["INTERNAL_CONFIG_FILE"].nil?
          @new_version_internal = Fastlane::Helpers::IosVersionHelper.create_internal_version(@current_version) unless ENV["INTERNAL_CONFIG_FILE"].nil?
          @new_short_version = Fastlane::Helpers::IosVersionHelper.get_short_version_string(@new_version)
          @new_release_branch = "release/#{@new_short_version}"
        end

        def self.show_config()
          UI.message("Current build version: #{@current_version}")
          UI.message("Current internal version: #{@current_version_internal}") unless ENV["INTERNAL_CONFIG_FILE"].nil?
          UI.message("New build version: #{@new_version}")
          UI.message("New internal version: #{@new_version_internal}") unless ENV["INTERNAL_CONFIG_FILE"].nil?
          UI.message("New short version: #{@new_short_version}")
          UI.message("Release branch: #{@new_release_branch}")
        end

        def self.update_glotpress_key()
          dm_file = ENV["DOWNLOAD_METADATA"]
          if (File.exist?(dm_file)) then
            sh("sed -i '' \"s/let glotPressWhatsNewKey.*/let glotPressWhatsNewKey = \\\"v#{@new_short_version}-whats-new\\\"/\" #{dm_file}")
          else
            UI.user_error!("Can't find #{dm_file}.")
          end
        end
      end
    end
  end