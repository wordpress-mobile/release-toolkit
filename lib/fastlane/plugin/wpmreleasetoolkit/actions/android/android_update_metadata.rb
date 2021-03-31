module Fastlane
  module Actions
    module SharedValues
      ANDROID_UPDATE_METADATA_CUSTOM_VALUE = :ANDROID_UPDATE_METADATA_CUSTOM_VALUE
    end

    class AndroidUpdateMetadataAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_git_helper.rb'

        Fastlane::Helper::Android::GitHelper.update_metadata(ENV['validate_translations'])
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Downloads translated metadata from the translation system (deprecated)'
      end

      def self.details
        'Downloads translated metadata from the translation system. This action is deprecated in favor of android_download_translations(…)'
      end

      def self.available_options
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
