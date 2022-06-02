module Fastlane
  module Actions
    class IosCheckBetaDepsAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper'
        require_relative '../../helper/ios/ios_git_helper'

        beta_pods = []
        File.open(params[:podfile]).each do |li|
          beta_pods << li if li.match('^\s*\t*pod.*beta')
        end

        if beta_pods.count == 0
          UI.message('No beta pods found. You can continue with the code freeze.')
        else
          message = "The following pods are still in beta:\n"
          beta_pods.each do |bpod|
            message << "#{bpod}\n"
          end
          message << 'Please update to the released version before continuing with the code freeze.'
        end
        UI.important(message)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs some prechecks before finalizing a release'
      end

      def self.details
        'Runs some prechecks before finalizing a release'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :podfile,
                                       env_name: 'FL_IOS_CHECKBETADEPS_PODFILE',
                                       description: 'Path to the Podfile to analyse',
                                       is_string: true),
        ]
      end

      def self.output
      end

      def self.return_value
        ''
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
