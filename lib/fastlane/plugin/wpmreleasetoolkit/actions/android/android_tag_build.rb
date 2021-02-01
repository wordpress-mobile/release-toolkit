module Fastlane
    module Actions
      class AndroidTagBuildAction < Action
        def self.run(params)
          require_relative '../../helper/android/android_version_helper.rb'
          require_relative '../../helper/android/android_git_helper.rb'
    
          release_ver = Fastlane::Helper::AndroidVersionHelper.get_release_version()
          alpha_ver = Fastlane::Helper::AndroidVersionHelper.get_alpha_version() unless ENV["HAS_ALPHA_VERSION"].nil?
          Fastlane::Helper::AndroidGitHelper.tag_build(release_ver[Fastlane::Helper::AndroidVersionHelper::VERSION_NAME], (ENV["HAS_ALPHA_VERSION"].nil? or (params[:tag_alpha] == false)) ? nil : alpha_ver[Fastlane::Helper::AndroidVersionHelper::VERSION_NAME])
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
          [
            FastlaneCore::ConfigItem.new(key: :tag_alpha,
                                         env_name: "FL_ANDROID_TAG_BUILD_ALPHA", 
                                         description: "True to skip tagging the alpha version", 
                                         is_string: false,
                                         default_value: true)
          ]
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