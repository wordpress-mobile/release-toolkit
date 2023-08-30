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
          (any_changes = Fastlane::Helper::Android::LocalizeHelper.merge_lib(main_strings_path, lib)) || any_changes
        end

        UI.message("Changes have been applied to #{main_strings_path}. Please, verify it!") if any_changes
      end

      def self.description
        'Merges the strings to be localised from the libs into the main application file'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
      end

      def self.details
        'Merges the strings to be localised from the libs into the main application file'
      end

      def self.available_options
        libs_hash_description = <<~KEYS
          - `:library`: The library display name.
          - `:strings_path`: The path to the `strings.xml` file of the library.
          - `:exclusions`: An optional `Array` of string keys to exclude from merging.
          - `:source_id`: An optional `String` which will be added as the `a8c-src-lib` XML attribute
            to strings coming from this library, to help identify their source in the merged file.
          - `:add_ignore_attr`: If set to true, will add `tools:ignore="UnusedResources"` to merged strings.
        KEYS
        [
          FastlaneCore::ConfigItem.new(key: :app_strings_path,
                                       description: 'The path of the main strings file',
                                       optional: false,
                                       type: String),
          # The name of this parameter is a bit misleading due to legacy. In practice it's expected to be an Array of Hashes, each describing a library to merge.
          # See `Fastlane::Helper::Android::LocalizeHelper.merge_lib`'s YARD doc for more details on the keys expected for each Hash.
          FastlaneCore::ConfigItem.new(key: :libs_strings_path,
                                       env_name: 'LOCALIZE_LIBS_STRINGS_PATH',
                                       description: "The list of libs to merge. Each item in the provided array must be a Hash with the following keys:\n#{libs_hash_description}",
                                       optional: false,
                                       type: Array),
        ]
      end

      def self.is_supported?(platform)
        return platform == :android
      end
    end
  end
end
