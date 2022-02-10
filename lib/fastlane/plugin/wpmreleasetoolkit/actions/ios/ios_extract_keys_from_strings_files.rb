module Fastlane
  module Actions
    class IosExtractKeysFromStringsFilesAction < Action
      def self.run(params)
        lprojs_parent_dir = params[:lprojs_parent_dir]
        source_strings_filename = "#{params[:source_tablename]}.strings"
        target_strings_filename = "#{params[:target_tablename]}.strings"
        base_lproj_dir = "#{params[:base_locale]}.lproj"

        # The file containing the originals (e.g. English copy) of the keys we want to extract -- e.g. `en-US.lproj/InfoPlist.strings`
        target_table_originals = File.join(lprojs_parent_dir, base_lproj_dir, target_strings_filename)
        begin
          keys_to_extract = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: target_table_originals).keys
        rescue StandardError => e
          UI.user_error!("Failed to read the keys to extract from originals file `#{target_table_originals}`: #{e.message}")
        end

        # For each locale, extract the `keys_to_extract` translations from `source_strings_filename` into `target_strings_filename`
        Dir.chdir(lprojs_parent_dir) do
          Dir.glob('*.lproj').each do |lproj_dir|
            next if lproj_dir == base_lproj_dir

            source_strings_file = File.join(lproj_dir, source_strings_filename)
            target_strings_file = File.join(lproj_dir, target_strings_filename)
            UI.message("Extracting #{keys_to_extract.count} keys into #{target_strings_file}...")

            translations = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: source_strings_file)
            translations.slice!(*keys_to_extract) # only keep the keys/translations we want to extract
            Fastlane::Helper::Ios::L10nHelper.generate_strings_file_from_hash(translations: translations, output_path: target_strings_file)
          rescue StandardError => e
            UI.error("Error while extracting keys from #{source_strings_file} into #{target_strings_file}: #{e.message}")
          end
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Extracts a subset of keys from a `.strings` file into a separate `.strings` file'
      end

      def self.details
        <<~DETAILS
          Extracts a subset of keys from a `.strings` file into a separate `.strings` file, for each `*.lproj` subdirectory.

          This is especially useful to extract keys for `InfoPlist.strings` or `<SomeIntentDefinitionFile>.strings`
          from the `Localizable.strings` file, for each locale.

          Since we typically merge all `*.strings` original files (e.g. `en.lproj/Localizable.strings` + `en.lproj/InfoPlist.strings`)
          via `ios_merge_strings_file` before sending the originals to translations, this is why we then need to extract
          the relevant keys and translations back into `InfoPlist.strings` after we pull those translations back from GlotPress
          (`ios_download_strings_files_from_glotpress`) using this `ios_extract_keys_from_strings_files` action.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :lprojs_parent_dir,
                                       env_name: 'FL_IOS_EXTRACT_KEYS_FROM_STRINGS_FILES_LPROJS_PARENT_DIR',
                                       description: 'The parent directory containing all the `*.lproj` subdirectories in which the `.strings` files reside',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :source_tablename,
                                       env_name: 'FL_IOS_EXTRACT_KEYS_FROM_STRINGS_FILES_SOURCE_TABLENAME',
                                       description: 'The basename of the `.strings` file (without the extension) to extract the keys and translations from',
                                       type: String,
                                       default_value: 'Localizable'),
          FastlaneCore::ConfigItem.new(key: :target_tablename,
                                       env_name: 'FL_IOS_EXTRACT_KEYS_FROM_STRINGS_FILES_TARGET_TABLENAME',
                                       description: 'The basename of the `.strings` file (without the extension) to extract the translations subset to',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :base_locale,
                                       env_name: 'FL_IOS_EXTRACT_KEYS_FROM_STRINGS_FILES_BASE_LOCALE',
                                       description: 'The basename of the `.lproj` directory which acts as reference/originals (e.g. `en-US` or `Base`). Used to determine which entries to extract, by looking at the keys present in `<base_locale>.lproj/<<target_tablename>.strings`',
                                       type: String),
        ]
      end

      def self.return_type
        # Describes what type of data is expected to be returned
        # see RETURN_TYPES in https://github.com/fastlane/fastlane/blob/master/fastlane/lib/fastlane/action.rb
        :array_of_strings
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
