module Fastlane
  module Actions
    class IosExtractKeysFromStringsFilesAction < Action
      def self.run(params)
        source_parent_dir = params[:source_parent_dir]
        target_original_files = params[:target_original_files].keys # Array [original-file-paths]
        keys_to_extract_per_target_file = keys_list_per_target_file(target_original_files) # Hash { original-file-path => [keys] }
        prefix_to_remove_per_target_file = params[:target_original_files] # Hash { original-file-path => prefix }

        UI.message("Extracting keys from `#{source_parent_dir}/*.lproj/#{params[:source_tablename]}.strings` into:")
        target_original_files.each { |f| UI.message(' - ' + replace_lproj_in_path(f, with_lproj: '*.lproj')) }

        updated_files_list = []

        # For each locale, extract the right translations from `<source_tablename>.strings` into each target `.strings` file
        Dir.glob('*.lproj', base: source_parent_dir).each do |lproj_dir_name|
          source_strings_file = File.join(source_parent_dir, lproj_dir_name, "#{params[:source_tablename]}.strings")
          translations = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: source_strings_file)

          target_original_files.each do |target_original_file|
            target_strings_file = replace_lproj_in_path(target_original_file, with_lproj: lproj_dir_name)
            next if target_strings_file == target_original_file # do not generate/overwrite the original locale itself

            keys_prefix = prefix_to_remove_per_target_file[target_original_file] || ''
            keys_to_extract = keys_to_extract_per_target_file[target_original_file].map { |k| "#{keys_prefix}#{k}" }
            extracted_translations = translations.slice(*keys_to_extract).transform_keys { |k| k.delete_prefix(keys_prefix) }
            UI.verbose("Extracting #{extracted_translations.count} keys (out of #{keys_to_extract.count} expected) into #{target_strings_file}...")

            FileUtils.mkdir_p(File.dirname(target_strings_file)) # Ensure path up to parent dir exists, create it if not.
            Fastlane::Helper::Ios::L10nHelper.generate_strings_file_from_hash(translations: extracted_translations, output_path: target_strings_file)
            updated_files_list.append(target_strings_file)
          rescue StandardError => e
            UI.user_error!("Error while writing extracted translations to `#{target_strings_file}`: #{e.message}")
          end
        rescue StandardError => e
          UI.user_error!("Error while reading the translations from source file `#{source_strings_file}`: #{e.message}")
        end

        updated_files_list
      end

      # Pre-load the list of keys to extract for each target file.
      #
      # @param [Array<String>] original_files array of paths to the originals of target files
      # @return [Hash<String, Array<String>>] The hash listing the keys to extract for each target file
      #
      def self.keys_list_per_target_file(original_files)
        original_files.to_h do |original_file|
          keys = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: original_file).keys
          [original_file, keys]
        end
      rescue StandardError => e
        UI.user_error!("Failed to read the keys to extract from originals file: #{e.message}")
      end

      # Replaces the `*.lproj` component of the path to a `.strings` file with a different `.lproj` folder
      #
      # @param [String] path The path the the `.strings` file, assumed to be in a `.lproj` parent folder
      # @param [String] with_lproj The new name of the `.lproj` parent folder to point to
      #
      def self.replace_lproj_in_path(path, with_lproj:)
        File.join(File.dirname(File.dirname(path)), with_lproj, File.basename(path))
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
                                       description: 'The path(s) to the `<base-locale>.lproj/<target-tablename>.strings` file(s) for which we want to extract the keys to, and the prefix to remove from their keys. ' \
                                        + 'Each key in the Hash should point to a file containing the original strings (typically `en` or `Base` locale), and will be used to determine which keys to extract from the `source_tablename`. ' \
                                        + 'For each key, the associated value is an optional prefix to remove from the keys (which can be useful if you used a prefix during `ios_merge_strings_files` to avoid duplicates). Can be nil or empty if no prefix was used during merge for that file.' \
                                        + 'Note: For each entry, the path(s) in which the translations will be extracted to will be the files with the same basename as the key in each of the other `*.lproj` sibling folders. ',
                                       type: Hash,
                                       verify_block: proc do |values|
                                         UI.user_error!('`target_original_files` must contain at least one path to an original `.strings` file.') if values.empty?
                                         values.each do |path, _|
                                           UI.user_error!("Path `#{path}` (found in `target_original_files`) does not exist.") unless File.exist?(path)
                                           UI.user_error! "Expected `#{path}` (found in `target_original_files`) to be a path ending in a `*.lproj/*.strings`." unless File.extname(path) == '.strings' && File.extname(File.dirname(path)) == '.lproj'
                                         end
                                       end),
        ]
      end

      def self.return_type
        :array_of_strings
      end

      def self.return_value
        'The list of files which have been generated and written to disk by the action'
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
