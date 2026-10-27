# frozen_string_literal: true

require 'yaml'
require 'tmpdir'

module Fastlane
  module Helper
    module Ios
      class L10nLinterHelper
        SWIFTGEN_VERSION = '6.6.2'
        DEFAULT_BASE_LANG = 'en'
        CONFIG_FILE_NAME = 'swiftgen-stringtypes.yml'

        # A printf-style placeholder at the start of a string, capturing its optional `N$` position and its conversion character.
        # `*` widths and precisions are deliberately not matched, as they consume an extra argument.
        PLACEHOLDER_REGEX = /\A%(?:(\d+)\$)?[-+ #0']*\d*(?:\.\d*)?(?:hh|h|ll|l|q|L|z|t|j)?([@dDiuUxXoOfFeEgGaAcCsSp])/
        PLACEHOLDER_TYPES = {
          '@' => :object,
          'c' => :char, 'C' => :char,
          's' => :c_string, 'S' => :c_string,
          'p' => :pointer
        }.merge(
          'dDiuUxXoO'.chars.to_h { |c| [c, :integer] },
          'fFeEgGaA'.chars.to_h { |c| [c, :float] }
        ).freeze

        attr_reader :install_path, :version

        # @param [String] install_path The path to install SwiftGen to. Usually something like "$PROJECT_DIR/vendor/swiftgen/#{SWIFTGEN_VERSION}".
        #        It's recommended to provide an absolute path here rather than a relative one, to ensure it's not dependent on where the action is run from.
        # @param [String] version The version of SwiftGen to use. This will be used both:
        #        - to check if the current version located in `install_path`, if it already exists, is the expected one
        #        - to know which version to download if there is not one installed in `install_path` yet
        #
        def initialize(install_path:, version: SWIFTGEN_VERSION)
          @install_path = install_path
          @version = version || SWIFTGEN_VERSION
        end

        # Check if SwiftGen is installed in the provided `install_path` and if so if the installed version matches the expected `version`
        #
        def check_swiftgen_installed
          return false unless File.exist?(swiftgen_bin)

          vers_string = `#{swiftgen_bin} --version`
          # The SwiftGen version string has this format:
          #
          # SwiftGen v6.4.0 (Stencil v0.13.1, StencilSwiftKit v2.7.2, SwiftGenKit v6.4.0)
          vers_string.include?("SwiftGen v#{version}")
        rescue StandardError
          false
        end

        # Download the ZIP of SwiftGen for the requested `version` and install it in the `install_path`
        #
        # @note This action nukes anything at `install_path` – if something already exists – prior to install SwiftGen there
        #
        def install_swiftgen!
          UI.message "Installing SwiftGen #{version} into #{install_path}"
          Dir.mktmpdir do |tmpdir|
            zipfile = File.join(tmpdir, "swiftgen-#{version}.zip")
            Action.sh('curl', '--fail', '--location', '-o', zipfile, "https://github.com/SwiftGen/SwiftGen/releases/download/#{version}/swiftgen-#{version}.zip")
            extracted_dir = File.join(tmpdir, "swiftgen-#{version}")
            Action.sh('unzip', zipfile, '-d', extracted_dir)

            FileUtils.rm_rf(install_path)
            FileUtils.mkdir_p(install_path)
            FileUtils.cp_r("#{extracted_dir}/.", install_path)
          end
        end

        # Install SwiftGen if necessary (if not installed yet with the expected version), then run the checks and returns the violations found, if any
        #
        # @param [String] input_dir The path (ideally absolute) to the directory containing the `.lproj` folders to parse
        # @param [String] base_lang The code name (i.e the basename of one of the `.lproj` folders) of the locale to use as the baseline
        # @param [String] fail_on_strings_not_in_base_language Whether to fail on strings not in base language
        # @param [Boolean] allow_omitted_placeholders Whether to accept translations that use only some of the base language placeholders. See `only_omits_placeholders?`.
        # @return [Hash<String, Array<String>>] A hash of violations, keyed by language code, whose values are the list of violation messages for that language
        #
        def run(input_dir:, base_lang: DEFAULT_BASE_LANG, only_langs: nil, fail_on_strings_not_in_base_language: true, allow_omitted_placeholders: false)
          check_swiftgen_installed || install_swiftgen!
          find_diffs(
            input_dir: input_dir,
            base_lang: base_lang,
            only_langs: only_langs,
            fail_on_strings_not_in_base_language: fail_on_strings_not_in_base_language,
            allow_omitted_placeholders: allow_omitted_placeholders
          )
        end

        # Whether a translation is safe to format with the base string's arguments while using only some of them.
        #
        # That's the case when every placeholder in the translation exists in the base string, at the same position and with the same type, and the translation has fewer placeholders.
        # Unused arguments are ignored at runtime, so this is legitimate when a language doesn't need a value.
        #
        # For example, the English "The latest post %1$@ has received %2$@ like.", where `%2$@` is always "1",
        # can be translated to Romanian as "Ultimul articol %1$@ a avut o apreciere.", discarding `%2$@`
        # because "o" is both the indefinite article and the number one for feminine nouns, so the digit would be redundant.
        #
        # @param [String] base The string in the base language
        # @param [String] translation The translated string
        # @return [Boolean] `false` if the translation is blank, or either string has a placeholder this can't parse, like the incomplete `%1$l`
        #
        def self.only_omits_placeholders?(base:, translation:)
          return false if translation.strip.empty?

          base_placeholders = placeholders(base)
          translation_placeholders = placeholders(translation)
          return false if base_placeholders.nil? || translation_placeholders.nil?
          return false unless translation_placeholders.size < base_placeholders.size

          translation_placeholders.all? { |position, type| base_placeholders[position] == type }
        end

        # Parses the printf-style placeholders of a string.
        #
        # @param [String] string The string to parse
        # @return [Hash<Integer, Symbol>, nil] The placeholder types keyed by argument position,
        #         or `nil` if a placeholder is malformed, the string mixes positional and sequential placeholders, or a position is reused with a different type
        #
        def self.placeholders(string)
          placeholders = {}
          styles = []
          index = 0
          while (index = string.index('%', index))
            if string[index + 1] == '%'
              index += 2
              next
            end

            match = PLACEHOLDER_REGEX.match(string[index..])
            return nil if match.nil?

            styles << (match[1].nil? ? :sequential : :positional)
            position = match[1]&.to_i || styles.count
            type = PLACEHOLDER_TYPES[match[2]]
            return nil if placeholders.key?(position) && placeholders[position] != type

            placeholders[position] = type
            index += match[0].length
          end
          styles.uniq.size > 1 ? nil : placeholders
        end

        ##################

        private

        # Path to the swiftgen binary installed at install_path
        def swiftgen_bin
          "#{install_path}/bin/swiftgen"
        end

        # Name to use for the generated files / output files of SwiftGen for each locale. Those files will be generated in the temporary directory to then diff them.
        def output_filename(lang)
          "L10nParamsList.#{lang}.txt"
        end

        # The Stencil template that we want SwiftGen to use to generate the output.
        # It iterates on every "table" (`.strings` file, in most cases there's only one, `Localizable.strings`),
        # and for each, iterates on every entry found to print the key and the corresponding types parsed by SwiftGen from the placeholders found in that translation
        def template_content
          <<~TEMPLATE
            {% macro recursiveBlock table item %}
              {% for string in item.strings %}
            {{string.key}} ==> [{{string.types|join:","}}]
              {% endfor %}
              {% for child in item.children %}
              {% call recursiveBlock table child %}
              {% endfor %}
            {% endmacro %}

            {% for table in tables %}
            {% call recursiveBlock table.name table.levels %}
            {% endfor %}
          TEMPLATE
        end

        # Create the template file and the config file, in the temp dir, to be used by SwiftGen when parsing the input files.
        #
        # @return [(String, Array<String>)] A tuple of (config_file_absolute_path, Array<langs>)
        #
        def generate_swiftgen_config!(input_dir, output_dir, only_langs: nil)
          # Create the template file
          template_path = File.absolute_path(File.join(output_dir, 'strings-types.stencil'))
          File.write(template_path, template_content)

          # Dynamically create a SwiftGen config which will cover all supported languages
          langs = Dir.chdir(input_dir) do
            Dir.glob('*.lproj/Localizable.strings').map { |loc_file| File.basename(File.dirname(loc_file), '.lproj') }
          end.sort
          langs.select! { |lang| only_langs.include?(lang) } unless only_langs.nil?

          config = {
            'input_dir' => input_dir,
            'output_dir' => output_dir,
            'strings' => langs.map do |lang|
              {
                'inputs' => ["#{lang}.lproj/Localizable.strings"],
                # Choose an unlikely separator (instead of the default '.') to avoid creating needlessly complex Stencil Context nested
                # structure just because we have '.' in the English sentences we use (instead of structured reverse-dns notation) for the keys
                'options' => { 'separator' => '____' },
                'outputs' => [{
                  'templatePath' => template_path,
                  'output' => output_filename(lang)
                }]
              }
            end
          }

          # Write SwiftGen config file
          config_file = File.join(output_dir, CONFIG_FILE_NAME)
          File.write(config_file, config.to_yaml)

          [config_file, langs]
        end

        # @return [Hash<String, String>] The raw `Localizable.strings` translations for a locale, keyed by string key
        def strings_for(input_dir, lang)
          Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: File.join(input_dir, "#{lang}.lproj", 'Localizable.strings'))
        end

        # Returns a Hash mapping the list of expected parameter types for each of the keys based in the %… placeholders found in their `.strings` files
        #
        # @param [String] dir The temporary directory in which the file to sort lines for is located
        # @param [String] lang The code for the locale we need to sort the output lines for
        # @return [Hash<String, String>] A hash whose keys are the strings keys, and corresponding value is a String describing the types expected as parameters.
        #
        def placeholder_types_for_keys(dir, lang)
          file = File.join(dir, output_filename(lang))
          return nil unless File.exist?(file)

          File.readlines(file).map do |line|
            line.match(/^(.*) ==> (\[[A-Za-z,]*\])$/)&.captures
          end.compact.to_h
        end

        # Prepares the template and config files, then run SwiftGen, run `diff` on each generated output against the baseline, and returns a Hash of the violations found.
        #
        # @param [String] input_dir The directory where the `.lproj` folders to scan are located
        # @param [String] base_lang The base language used as source of truth that all other languages will be compared against
        # @param [Array<String>] only_langs The list of languages to limit the generation for. Useful to focus only on a couple of issues or just one language
        # @param [Boolean] fail_on_strings_not_in_base_language Whether to fail on strings not in base language
        # @param [Boolean] allow_omitted_placeholders Whether to accept translations that use only some of the base language placeholders
        # @return [Hash<String, Array<String>>] A hash of violations, keyed by language code, whose values are the list of violation messages for that language
        #
        # @note The returned Hash contains keys only for locales with violations. Locales parsed but without any violations found will not appear in the resulting hash.
        #
        def find_diffs(input_dir:, base_lang:, only_langs: nil, fail_on_strings_not_in_base_language: true, allow_omitted_placeholders: false)
          Dir.mktmpdir('a8c-lint-translations-') do |tmpdir|
            # Run SwiftGen
            langs = only_langs.nil? ? nil : (only_langs + [base_lang]).uniq
            (config_file, langs) = generate_swiftgen_config!(input_dir, tmpdir, only_langs: langs)
            Action.sh(swiftgen_bin, 'config', 'run', '--config', config_file)

            # Run diffs
            params_for_base_lang = placeholder_types_for_keys(tmpdir, base_lang)
            langs.delete(base_lang)
            base_strings = nil
            return langs.map do |lang|
              params_for_lang = placeholder_types_for_keys(tmpdir, lang)
              lang_strings = nil

              # If the lang ends up not having any translation at all (e.g. a `.lproj` without any `.strings` file in it but maybe just a storyboard or assets catalog), ignore it
              next nil if params_for_lang.nil? || params_for_lang.empty?

              violations = params_for_lang.map do |key, param_types|
                next "`#{key}` was unexpected, as it is not present in the base locale." if params_for_base_lang[key].nil? && fail_on_strings_not_in_base_language
                next if params_for_base_lang[key].nil? || params_for_base_lang[key] == param_types

                # SwiftGen's type lists drop argument positions, so omissions are checked against the raw strings instead.
                if allow_omitted_placeholders
                  base_strings ||= strings_for(input_dir, base_lang)
                  lang_strings ||= strings_for(input_dir, lang)
                  next if self.class.only_omits_placeholders?(base: base_strings[key].to_s, translation: lang_strings[key].to_s)
                end

                "`#{key}` expected placeholders for #{params_for_base_lang[key]} but found #{param_types} instead."
              end.compact

              [lang, violations] unless violations.empty?
            end.compact.to_h
          end
        end
      end
    end
  end
end
