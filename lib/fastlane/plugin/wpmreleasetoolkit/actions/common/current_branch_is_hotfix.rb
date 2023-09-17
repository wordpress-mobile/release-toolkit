module Fastlane
  module Actions
    module SharedValues
      CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE = :CURRENT_BRANCH_IS_HOTFIX_CUSTOM_VALUE
    end

    class CurrentBranchIsHotfixAction < Action
      def self.run(params)
        require_relative '../../calculators/version_calculator'
        version_object = params[:version_object]

        Fastlane::Calculators::VersionCalculator.new(version_object).patch?
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Checks if the current branch is for a hotfix'
      end

      def self.details
        'Checks if the current branch is for a hotfix'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version_object,
                                       env_name: 'FL_VERSION_OBJECT',
                                       description: 'The version object passed in from `read_value_from_file_action`',
                                       optional: true,
                                       is_string: false),
        ]
      end

      def self.output
      end

      def self.return_value
        'True if the branch is for a hotfix, false otherwise'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
