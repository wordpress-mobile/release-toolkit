require 'fastlane/action'
require_relative '../../helper/android/android_localize_helper'

module Fastlane
  module Actions
    class AnLocalizeLibsAction < Action
      def self.run(params)
        main_strings_path = params[:app_strings_path]
        libraries_strings_path = params[:libs_strings_path]

        any_changes = false
        libraries_strings_path.each do |lib|
          any_changes = Fastlane::Helper::AndroidLocalizeHelper.merge_lib(main_strings_path, lib) or any_changes
        end

        if (any_changes)
          UI.message("Changes have been applied to #{main_strings_path}. Please, verify it!")
        end
      end

      def self.description
        'Merges the strings to be localised from the libs into the main application file'
      end

      def self.authors
        ['Lorenzo Mattei']
      end

      def self.return_value
      end

      def self.details
        'Merges the strings to be localised from the libs into the main application file'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_strings_path,
                                       description: 'The path of the main strings file',
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :libs_strings_path,
                                       env_name: 'LOCALIZE_LIBS_STRINGS_PATH',
                                       description: 'The list of libs to merge',
                                       optional: false,
                                       is_string: false)
        ]
      end

      def self.is_supported?(platform)
        return platform == :android
      end
    end
  end
end
