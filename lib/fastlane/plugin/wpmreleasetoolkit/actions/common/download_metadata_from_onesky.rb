require 'fastlane/action'
require 'onesky'

module Fastlane
  module Actions
    class DownloadMetadataFromOnesky < Action
      def self.run(params)
        metadata_files = params[:metadata_files]

        UI.message('Downloading translations from Shared OneSky project...')
        keys = metadata_files.values.map { |h| h[:key] }.compact.map(&:to_s)
        alts = metadata_files.values.map { |h| h[:alt] }.compact.map(&:to_s)
        metadata_translations = fetch_translations(
          onesky_project: onesky_project(params),
          source_file_name: params[:source_file_name],
          locales: params[:locale],
          keys: keys + alts
        )

        changed_files = []
        metadata_files.each do |file, config|
          translations = metadata_translations[config[:key]]
          translations.each do |lang, text|
            if lang == 'en-US' && config[:skip_enUS] == true
              UI.message(" - Skipping updating #{lang}/#{file}, because `skip_enUS` was set")
              next
            end

            # If translation is too long, check to see if we can use the alternative key instead
            key, text = check_alternative_key(text: text, lang: lang, file: file, config: config, metadata_translations: metadata_translations)
            # Then update the txt file if the text is within the limit and the file isn't up-to-date yet
            changed_files << update_metadata_file(key: key, text: text, lang: lang, file: file, config: config)
          end
        end
        changed_files.compact
      end

      def self.onesky_project(params)
        onesky_client = Onesky::Client.new(params[:onesky_api_key], params[:onesky_api_secret])
        onesky_client.project(params[:onesky_project_id])
      end

      # Get the translations for the specified phrase IDs (all of them if `only = nil`) for all locales
      # @param [OneSky::Project] onesky_project The project object to use to export translations via the API
      # @param [String] source_file_name The name of the source file associated with those entries in OneSky
      # @param [Hash] locales A Hash whose keys are the OneSky locale codes to download, and values are corresponding (App/Play) Store locale codes
      # @param [Array<String>] keys List of phrase IDs (aka string keys) we want to download
      # @return [Hash<String, Hash<String, String>>]
      #         A Hash whose keys are the phrase IDs (aka string keys), and the values for each key is a sub-hash
      #         indexed by the Store locale name (e.g. `en-US`, `fr-FR`) with their corresponding translations as value.
      #
      def self.fetch_translations(onesky_project:, source_file_name:, locales:, keys:)
        translations = {}
        body = onesky_project.export_multilingual(source_file_name: source_file_name, file_format: 'I18NEXT_MULTILINGUAL_JSON')
        json = JSON.parse(body.to_s)

        locales.each do |onesky_locale, store_locale|
          locale_translations = json[onesky_locale]['translation']
          keys.each do |key|
            translations[key] ||= {}
            parts = key.split('.') # OneSky splits keys containing `.` into nested JSON entries
            lines = locale_translations.dig(*parts)
            translations[key][store_locale] = lines.nil? ? nil : Array(lines).join("\n")
          end
        end
        translations
      end

      # Check if the translation for primary key is too long, and if so, update the key and text variables to use the alternative one, if one exists
      #
      # @param [String] text The translation copy to check for length
      # @param [String] lang The language code we are checking for
      # @param [String] file The basename of the file we're trying to update (only used in log messages)
      # @param [Hash] config The configuration associated with the entry in `metadata_files` (to check for `:max` & `:alt` keys)
      # @param [Hash] metadata_translations The hash that was returned by `get_translations` and contains all the `{ key: { lang: "copy" } }` translations
      #
      # @return [(String, String)] Returns the key and text to use based on this length check.
      #
      def self.check_alternative_key(text:, lang:, file:, config:, metadata_translations:)
        key = config[:key].to_s
        text += config[:suffix] || '' unless text.nil?

        if !config[:max].nil? && (text.nil? || text.empty? || text.length > config[:max])
          alt_key = config[:alt].to_s
          alt_text = metadata_translations.dig(alt_key, lang)
          unless alt_text.nil?
            UI.message(" ! Translation for #{lang}/#{file} (#{key}) is missing or longer than #{config[:max]} characters. Trying alternative key (#{alt_key})...")
            key = alt_key
            text = alt_text + (config[:suffix] || '')
          end
        end
        [key, text]
      end

      # Update a given `.txt` file with the new translation, unless the file is already up-to-date or the copy is longer than the limit
      #
      # @param [String] key The key the translation comes from (only used in log messages)
      # @param [String] text The translation copy to check for length
      # @param [String] lang The language code we are checking for
      # @param [String] file The basename of the file we're trying to update. (Only used in logging messages)
      # @param [Hash] config The configuration associated with the entry in `metadata_files` (to check for `:max` & `:alt` keys)
      #
      # @return [String] The path of the file if it has been modified, nil if not. Useful to know which files to git-commit after calling this.
      #
      def self.update_metadata_file(key:, text:, lang:, file:, config:)
        metadata_dir = runner.current_platform == :android ? File.join('metadata', 'android') : 'metadata'
        path = File.join(metadata_dir, lang, file.to_s)

        if !config[:max].nil? && (text.nil? || text.empty? || text.length > config[:max])
          UI.error(" ! Translation for #{lang}/#{file} (#{key}) is missing or longer than #{config[:max]} characters, so it was not updated.")
          nil
        elsif File.read(path).chomp == text.chomp
          UI.message(" ✓ Translation for #{lang}/#{file} was already up-to-date.")
          nil
        else
          File.write(path, "#{text.chomp}\n") # Ensure newline at end of file
          UI.success(" 🆕 Updated translation for #{lang}/#{file}.")
          File.join('fastlane', path)
        end
      end

      ####################################################

      def self.description
        'Downloads store metadata translations from OneSky (oneskyapp.com)'
      end

      def self.return_value
        'The list of files that got updated and should be commited'
      end

      def self.details
        <<~DETAILS
          Downloads App Store / Play Store metadata translations (app title, description, …) from a OneSky project in oneskyapp.com
          and store them in `.txt` files in the relevant folders under `fastlane/metadata/`
        DETAILS
      end

      def self.example_code
        [
          <<~EXAMPLE1,
            ENV['ONESKY_API_KEY'] = …
            ENV['ONESKY_API_SECRET'] = …
            ENV['ONESKY_PROJECT_ID'] = '123456'
            ENV['ONESKY_SOURCE_FILE_NAME'] = 'store-metadata.xml'

            # Those file names and max limits typically correspond to Android metadata
            metadata_files = {
              'title.txt': { key: 'app_title', max: 30 },
              'short_description.txt': { key: app_subtitle_10_2021, max: 80 },
              'full_description.txt': {
                key: 'app_description_8_2023',
                max: 4000,
                alt: 'app_description_8_2023_short',
                # The copy we actually use for English in the store is different from the (shorter) English copy we provide translators in OneSky
                skip_enUS: true # So we don't want to update en-US/full_description.txt with the OneSky English copy.
              },
              'changelogs/default.txt': { key: release_notes_id, max: 500 }
            }
            changed_files = download_metadata_from_onesky(
              metadata_files: metadata_files,
              locales: LocalesMap.default.to_h(:onesky, :google_play)
            )
            # Then you can call `git_add`+`git_commit` passing those `changed_files`, for example
          EXAMPLE1
          <<~EXAMPLE2,
            # Those file names and max limits typically correspond to iOS metadata
            metadata_files = {
              'name.txt': { key: 'app_title', max: 30 },
              'subtitle.txt': { key: app_subtitle_10_2021, max: 30 },
              'promotional_text.txt': { key: nil, max: 170 },
              'keywords.txt': { key: 'app_keywords_5_2021', max: 100 },
              'description.txt': {
                key: 'app_description_8_2023',
                max: 4000,
                alt: 'app_description_8_2023_short',
                # The copy we actually use for English in ASC is different from the (shorter) English copy we provide translators in OneSky
                skip_enUS: true # So we don't want to update en-US/description.txt with the OneSky Engish copy.
              },
              'release_notes.txt': { key: release_notes_id, max: 4000 }
            }
            changed_files = download_metadata_from_onesky(
              onesky_api_key: '…',
              onesky_api_secret: '…',
              onesky_project_id: 123_456,
              source_file_name: 'store-metadata.xml',
              metadata_files: metadata_files,
              locales: LocalesMap.default.to_h(:onesky, :app_store)
            )
            # Then you can call `git_add`+`git_commit` passing those `changed_files`, for example
          EXAMPLE2
        ]
      end

      def self.available_options
        metadata_files = <<~DESC
          A hash where each key is the relative path to of a `metadata/*.txt` file, and the corresponding value is another hash with the following keys:
            - key:    The OneSky phraseIDs, aka the string keys.
            - suffix: An optional suffix to add at the end of all the translations.
            - max:    If specified, the maximum number of characters allowed for that copy. If the translation exceeds that length, it will be skipped.
            - alt:    If both this and `max` are specified and the translation is longer than `max`, they try to use the translation for the `alt` key instead.
            - skip_enUS: If set to true, will not update the file for the `en-US` locale. This might be useful if we intentionally use a different
                      (and potentially longer) copy for English vs the English copy we uploaded to OneSky to get shorter translations'
        DESC
        [
          FastlaneCore::ConfigItem.new(key: :onesky_api_key,
                                       env_name: 'ONESKY_API_KEY',
                                       description: 'The public key needed to access OneSky API',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :onesky_api_secret,
                                       env_name: 'ONESKY_API_SECRET',
                                       description: 'The API secret needed to access OneSky API',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :onesky_project_id,
                                       env_name: 'ONESKY_PROJECT_ID',
                                       description: 'The project ID containing the translations to download',
                                       optional: false,
                                       type: Integer),
          FastlaneCore::ConfigItem.new(key: :source_file_name,
                                       env_name: 'ONESKY_SOURCE_FILE_NAME',
                                       description: 'The name of the source file in OneSky to fetch translations from',
                                       optional: false,
                                       default_value: 'Manually input_new',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :metadata_files,
                                       description: metadata_files,
                                       optional: false,
                                       type: Hash),
          FastlaneCore::ConfigItem.new(key: :locales,
                                       description: 'A Hash of { OneSky locale code => App/Play Store locale code }. ' \
                                        + 'Tip: you may use `LocalesMap` as a helper to provide those values',
                                       optional: false,
                                       type: Hash),
        ]
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
