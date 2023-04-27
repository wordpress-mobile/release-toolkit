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
        <<~DETAILS
          Checks that the strings to be localised are updated from the libs into the main application file

          For the `lib_strings_path` ConfigItem, it is an array of Hashes, each describing a library and
          containing these specific keys:
            - `:library`: The human readable name of the library, used to display in console messages
            - `:strings_path`: The path to the strings.xml file of the library to merge into the main one
            - `:exclusions`: An array of strings keys to exclude during merge. Any of those keys from the
               library's `strings.xml` will be skipped and won't be merged into the main one.
            - `:source_id`: An optional `String` which will be added as the `a8c-src-lib` XML attribute
               to strings coming from this library, to help identify their source in the merged file.
            - `:add_ignore_attr`: If set to `true`, will add `tools:ignore="UnusedResources"` to merged strings.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_strings_path,
                                       description: 'The path of the main strings file',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :libs_strings_path,
                                       env_name: 'CHECK_LIBS_STRINGS_PATH',
                                       description: 'The list of libs to merge. This should be an array of Hashes.',
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
