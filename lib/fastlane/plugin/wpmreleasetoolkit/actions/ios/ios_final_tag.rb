module Fastlane
  module Actions
    class IosFinalTagAction < Action
      def self.run(params)
        return unless UI.confirm("#{deprecated_notes} Would you like to continue with the action?")

        require_relative '../../helper/ios/ios_git_helper'
        require_relative '../../helper/ios/ios_version_helper'
        version = Fastlane::Helper::Ios::VersionHelper.get_public_version

        UI.message("Tagging final #{version}...")

        Fastlane::Helper::GitHelper.create_tag(version)

        other_action.ios_clear_intermediate_tags(version: version)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Finalize a relasae'
      end

      def self.details
        'Removes the temp tags and pushes the final one'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: 'FL_IOS_FINAL_TAG_VERSION',
                                       description: 'The version of the release to finalize',
                                       type: String),
        ]
      end

      def self.output
      end

      def self.return_value
      end

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        "This action is deprecated as we don't believe it's currently in use in our projects.
        However, just to be sure that it's not in use, we decided to deprecate it first. If you
        believe that this is a mistake, please let us know on Slack."
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
