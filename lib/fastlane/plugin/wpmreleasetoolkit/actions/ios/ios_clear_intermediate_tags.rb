module Fastlane
  module Actions
    class IosClearIntermediateTagsAction < Action
      def self.run(params)
        UI.message("Deleting tags for version: #{params[:version]}")

        require_relative '../../helper/git_helper.rb'
        Fastlane::Helper::Ios::GitHelper.delete_tags(params[:version])

        # Cleanup local tags and refetch them to make sure we're up-to-date with remote
        local_tags = Fastlane::Helper::GitHelper.list_local_tags()
        Fastlane::Helper::GitHelper.delete_tags(local_tags, delete_on_remote: true)
        Fastlane::Helper::GitHelper.fetch_all_tags()

        # Now delete intermediate tags (4-parts version names starting with our version number)
        parts = params[:version].split('.')
        pattern = parts.fill('*', parts.length...4).join('.') # "1.2.*.*" or "1.2.3.*"
        intermediate_tags = Fastlane::Helper::GitHelper.list_local_tags(matching: pattern)
        Fastlane::Helper::GitHelper.delete_tags(intermediate_tags, delete_on_remote: true)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Cleans all the intermediate tags for the given version'
      end

      def self.details
        'Cleans all the intermediate tags for the given version'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: 'FL_IOS_CLEAN_INTERMEDIATE_TAGS_VERSION',
                                       description: 'The version of the tags to clear',
                                       is_string: true)
        ]
      end

      def self.output

      end

      def self.return_value

      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
