require 'fastlane/action'
require_relative '../../helper/git_helper'
module Fastlane
  module Actions
    class CheckoutAndPullAction < Action
      def self.run(params)
        branch_name = params[:branch_name]

        Fastlane::Helper::GitHelper.checkout_and_pull(branch_name)
      end

      def self.description
        'Checkout and pull the specified branch'
      end

      def self.return_value
        'True if it succeeded switching and pulling, false if there was an error during the switch or pull.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :branch_name,
                                       env_name: 'BRANCH_NAME_TO_CHECKOUT_AND_PULL',
                                       description: 'The name of the branch to checkout and pull',
                                       optional: false,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.authors
        ['Automattic']
      end
    end
  end
end
