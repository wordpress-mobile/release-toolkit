module Fastlane
  module Actions
    class IosExtractKeysFromStringsFilesAction < Action
      def self.run(params)
        source_parent_dir = params[:source_parent_dir]
        target_original_files = params[:target_original_files]
        keys_to_extract_per_target_file = keys_list_per_target_file(target_original_files)

        # For each locale, extract the right translations from `<source_tablename>.strings` into each target `.strings` file
        Dir.glob('*.lproj', base: source_parent_dir).each do |lproj_dir_name|
          source_strings_file = File.join(source_parent_dir, lproj_dir_name, "#{params[:source_tablename]}.strings")
          translations = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: source_strings_file)

          target_original_files.each do |target_original_file|
            target_strings_file = File.join(File.dirname(File.dirname(target_original_file)), lproj_dir_name, File.basename(target_original_file))
            next if target_strings_file == target_original_file # do not generate/overwrite the original locale itself

            keys_to_extract = keys_to_extract_per_target_file[target_original_file]
            extracted_translations = translations.slice(*keys_to_extract)
            UI.message("Extracting #{extracted_translations.count} keys (out of #{keys_to_extract.count} expected) into #{target_strings_file}...")

            FileUtils.mkdir_p(File.dirname(target_strings_file)) # Ensure path up to parent dir exists, create it if not.
            Fastlane::Helper::Ios::L10nHelper.generate_strings_file_from_hash(translations: extracted_translations, output_path: target_strings_file)
          rescue StandardError => e
            UI.user_error!("Error while writing extracted translations to `#{target_strings_file}`: #{e.message}")
          end
        rescue StandardError => e
          UI.user_error!("Error while reading the translations from source file `#{source_strings_file}`: #{e.message}")
        end
      end

      # Pre-load the list of keys to extract for each target file.
      #
      # @param [Array<String>] original_files array of paths to the originals of target files
      # @return [Hash<String, Array<String>>] The hash listing the keys to extract for each target file
      #
      def self.keys_list_per_target_file(original_files)
        original_files.map do |original_file|
          keys = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: original_file).keys
          [original_file, keys]
        end.to_h
      rescue StandardError => e
        UI.user_error!("Failed to read the keys to extract from originals file: #{e.message}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Extracts a subset of keys from a `.strings` file into separate `.strings` file(s)'
      end

      def self.details
        <<~DETAILS
          Extracts a subset of keys from a `.strings` file into separate `.strings` file(s), for each `*.lproj` subdirectory.

          This is especially useful to extract, for each locale, the translations for files like `InfoPlist.strings` or
          `<SomeIntentDefinitionFile>.strings` from the `Localizable.strings` file that we exported/downloaded back from GlotPress.

          Since we typically merge all `*.strings` original files (e.g. `en.lproj/Localizable.strings` + `en.lproj/InfoPlist.strings` + …)
          via `ios_merge_strings_file` before sending the originals to translations, we then need to extract the relevant keys and
          translations back into the `*.lproj/InfoPlist.strings` after we pull those translations back from GlotPress
          (`ios_download_strings_files_from_glotpress`). This is what this `ios_extract_keys_from_strings_files` action is for.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :source_parent_dir,
                                       env_name: 'FL_IOS_EXTRACT_KEYS_FROM_STRINGS_FILES_SOURCE_PARENT_DIR',
                                       description: 'The parent directory containing all the `*.lproj` subdirectories in which the source `.strings` files reside',
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("`source_parent_dir` should be a path to an existing directory, but found `#{value}`.") unless File.directory?(value)
                                         UI.user_error!("`source_parent_dir` should contain at least one `.lproj` subdirectory, but `#{value}` does not contain any.") if Dir.glob('*.lproj', base: value).empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :source_tablename,
                                       env_name: 'FL_IOS_EXTRACT_KEYS_FROM_STRINGS_FILES_SOURCE_TABLENAME',
                                       description: 'The basename of the `.strings` file (without the extension) to extract the keys and translations from for each locale',
                                       type: String,
                                       default_value: 'Localizable'),
          FastlaneCore::ConfigItem.new(key: :target_original_files,
                                       env_name: 'FL_IOS_EXTRACT_KEYS_FROM_STRINGS_FILES_TARGET_ORIGINAL_FILES',
                                       description: 'The path(s) to the `<base-locale>.lproj/<target-tablename>.strings` file(s) for which we want to extract the keys to. ' \
                                        + 'Each of those files should containing the original strings (typically `en` or `Base` locale) and will be used to determine which keys to extract from the `source_tablename`. ' \
                                        + 'For each of those, the path(s) in which the translations will be extracted will be the files with the same basename in each of the other `*.lproj` sibling folders',
                                       type: Array,
                                       verify_block: proc do |values|
                                         UI.user_error!('`target_original_files` must contain at least one path to an original `.strings` file.') if values.empty?
                                         values.each do |v|
                                           UI.user_error!("Path `#{v}` (found in `target_original_files`) does not exist.") unless File.exist?(v)
                                           UI.user_error! "Expected `#{v}` (found in `target_original_files`) to be a path ending in a `*.lproj/*.strings`." unless File.extname(v) == '.strings' && File.extname(File.dirname(v)) == '.lproj'
                                         end
                                       end),
        ]
      end

      def self.return_type
        # Describes what type of data is expected to be returned
        # see RETURN_TYPES in https://github.com/fastlane/fastlane/blob/master/fastlane/lib/fastlane/action.rb
        nil
      end

      def self.return_value
        # Freeform textual description of the return value
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
