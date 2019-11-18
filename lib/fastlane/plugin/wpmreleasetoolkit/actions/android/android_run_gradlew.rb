module Fastlane
    module Actions
      class AndroidRunGradlewAction < Action
        def self.run(params)
          Action.sh("./gradlew #{params[:command]}")
        end
        #####################################################
        # @!group Documentation
        #####################################################
    
        def self.description
          "runs gradlew for android"
        end
    
        def self.details
          "runs gradlew with specified command"
        end

        def self.available_options
          [
            FastlaneCore::ConfigItem.new(key: :command,
                                         env_name: "FL_ANDROID_GRADLEW_COMMAND", 
                                         description: "specify command for running gradlew", 
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