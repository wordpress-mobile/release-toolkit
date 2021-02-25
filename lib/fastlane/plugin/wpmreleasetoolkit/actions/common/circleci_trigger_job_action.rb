module Fastlane
  module Actions
    class CircleciTriggerJobAction < Action
      def self.run(params)
        require_relative '../../helper/ci_helper.rb'

        UI.message "Triggering job #{params[:job_params]} on branch #{params[:branch]}"

        ci_helper = Fastlane::Helper::CircleCIHelper.new(
          login: params[:circle_ci_token],
          repository: params[:repository],
          organization: params[:organization]
        )

        res = ci_helper.trigger_job(branch: params[:branch], parameters: params[:job_params])
        res.code == '201' ? UI.message('Done!') : UI.user_error!("Failed to start job\nError: [#{res.code}] #{res.message}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Triggers a job on CircleCI'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :circle_ci_token,
                                       env_name: 'FL_CIRCLECI_TOKEN',
                                       description: 'CircleCI token',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :organization,
                                       env_name: 'FL_CIRCLECI_ORGANIZATION',
                                       description: 'The GitHub organization which hosts the repository you want to work on',
                                       type: String,
                                       default_value: 'wordpress-mobile'),
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'FL_CIRCLECI_REPOSITORY',
                                       description: 'The GitHub repository you want to work on',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: 'FL_CIRCLECI_BRANCH',
                                       description: 'The branch on which you want to work on',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :job_params,
                                       env_name: 'FL_CIRCLECI_JOB_PARAMS',
                                       description: 'Parameters to send to the CircleCI pipeline',
                                       type: Hash,
                                       default_value: nil),
        ]
      end

      def self.authors
        ['loremattei']
      end
    end
  end
end
