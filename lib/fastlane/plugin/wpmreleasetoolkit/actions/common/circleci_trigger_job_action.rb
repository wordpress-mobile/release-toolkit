module Fastlane
    module Actions    
        class CircleciTriggerJobAction < Action
            def self.run(params)
                require_relative '../../helper/ci_helper.rb'
                
                UI.message "Triggering job #{params[:job_params]} on branch #{params[:branch]}"

                ci_helper = Fastlane::Helper::CircleCIHelper.new(
                    params[:circle_ci_token],
                    params[:repository],
                    params[:organization]
                )

                res = ci_helper.trig_job(params[:branch], params[:job_params])
                (res.code == "201") ? UI.message("Done!") : UI.user_error!("Failed to start job\nError: [#{res.code}] #{res.message}")
            end
  
            #####################################################
            # @!group Documentation
            #####################################################
  
            def self.description
                "Triggers a job on CircleCI"
            end
  
            def self.available_options
            [
                FastlaneCore::ConfigItem.new(key: :circle_ci_token,
                                            env_name: "FL_CCI_TOKEN",
                                            description: "CircleCI token",
                                            is_string: true), 
                FastlaneCore::ConfigItem.new(key: :organization,
                                            env_name: "FL_CCI_ORGANIZATION",
                                            description: "The GitHub organization which hosts the repository you want to work on",
                                            is_string: true,
                                            default_value: "wordpress-mobile"), 
                FastlaneCore::ConfigItem.new(key: :repository,
                                            env_name: "FL_CCI_REPOSITORY",
                                            description: "The GitHub repository you want to work on",
                                            is_string: true),  
                FastlaneCore::ConfigItem.new(key: :branch,
                                            env_name: "FL_CCI_BRANCH",
                                            description: "The branch on which you want to work on",
                                            is_string: true),
                FastlaneCore::ConfigItem.new(key: :job_params,
                                            env_name: "FL_CCI_JOB_PARAMS",
                                            description: "Parameters to send to the CircleCI pipeline",
                                            is_string: false,
                                            default_value: nil),                      
            ]
            end
  
            def self.authors
                ["loremattei"]
            end
        end
    end
end
