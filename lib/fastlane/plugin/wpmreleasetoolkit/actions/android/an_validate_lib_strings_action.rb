require 'fastlane/action'
require_relative '../../helper/android/android_localize_helper'

module Fastlane
  module Actions
    class AnValidateLibStringsAction < Action
      def self.run(params)
        main_strings_path = params[:app_strings_path]
        libraries_strings_path = params[:libs_strings_path]
        diff_url = params[:diff_url]

        source_diff = nil
        if diff_url.nil? == false
          data = open(params[:diff_url])
          source_diff = data.read()
        end

        any_error = false
        libraries_strings_path.each do |lib|
          Fastlane::Helper::Android::LocalizeHelper.verify_lib(main_strings_path, lib, source_diff)
        end
      end

      def self.description
        'Checks that the strings to be localised are updated from the libs into the main application file'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
      end

      def self.details
        'Checks that the strings to be localised are updated from the libs into the main application file'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_strings_path,
                                       description: 'The path of the main strings file',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :libs_strings_path,
                                       env_name: 'CHECK_LIBS_STRINGS_PATH',
                                       description: 'The list of libs to merge',
                                       optional: false,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :diff_url,
                                       env_name: 'CHECK_LIBS_DIFF_URL',
                                       description: 'The url of the diff to check',
                                       optional: true,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        return platform == :android
      end
    end
  end
end
