module Fastlane
    module Actions    
      class AndroidBumpVersionReleaseAction < Action
        def self.run(params)
          # fastlane will take care of reading in the parameter and fetching the environment variable:
          UI.message "Bumping app release version..."

          require_relative '../../helper/android/android_version_helper.rb'
          require_relative '../../helper/android/android_git_helper.rb'
          
          other_action.ensure_git_branch(branch: "develop")

          # Create new configuration
          @new_short_version = Fastlane::Helper::Android::VersionHelper.bump_version_release()
          create_config()
          show_config()

          # Update local develop and branch
          UI.message "Creating new branch..."
          Fastlane::Helper::GitHelper.create_branch(@new_release_branch, from: "develop")
          UI.message "Done!"

          UI.message "Updating versions..."
          Fastlane::Helper::Android::VersionHelper.update_versions(@new_version_beta, @new_version_alpha) 
          Fastlane::Helper::Android::GitHelper.commit_version_bump()         
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
          platform == :android
        end


        private
        def self.create_config()
          @current_version = Fastlane::Helper::Android::VersionHelper.get_release_version()
          @current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version()
          @new_version_beta = Fastlane::Helper::Android::VersionHelper.calc_next_release_version(@current_version, @current_version_alpha)
          @new_version_alpha = ENV["HAS_ALPHA_VERSION"].nil? ? nil : Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(@new_version_beta, @current_version_alpha)
          @new_release_branch = "release/#{@new_short_version}"
        end

        def self.show_config()
          vname = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
          vcode = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
          UI.message("Current version: #{@current_version[vname]}(#{@current_version[vcode]})")
          UI.message("Current alpha version: #{@current_version_alpha[vname]}(#{@current_version_alpha[vcode]})") unless ENV["HAS_ALPHA_VERSION"].nil?
          UI.message("New beta version: #{@new_version_beta[vname]}(#{@new_version_beta[vcode]})")
          UI.message("New alpha version: #{@new_version_alpha[vname]}(#{@new_version_alpha[vcode]})") unless ENV["HAS_ALPHA_VERSION"].nil?
          UI.message("New version: #{@new_short_version}")
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
