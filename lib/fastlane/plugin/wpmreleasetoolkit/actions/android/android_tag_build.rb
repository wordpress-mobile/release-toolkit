module Fastlane
    module Actions
      class AndroidTagBuildAction < Action
        def self.run(params)
          require_relative '../../helper/android/android_version_helper.rb'
          require_relative '../../helper/android/android_git_helper.rb'
    
          release_ver = Fastlane::Helpers::AndroidVersionHelper.get_release_version()
          alpha_ver = Fastlane::Helpers::AndroidVersionHelper.get_alpha_version() unless ENV["HAS_ALPHA_VERSION"].nil?
          Fastlane::Helpers::AndroidGitHelper.tag_build(release_ver[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME], ENV["HAS_ALPHA_VERSION"].nil? ? nil : alpha_ver[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME])
        end
    
        #####################################################
        # @!group Documentation
        #####################################################
    
        def self.description
          "Tags the current build"
        end
    
        def self.details
          "Tags the current build"
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
      end
    end
  end