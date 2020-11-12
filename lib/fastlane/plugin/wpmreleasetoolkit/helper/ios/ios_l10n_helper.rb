require 'yaml'
require 'tmpdir'

module Fastlane
    module Helpers
      class IosL10nHelper
        SWIFTGEN_VERSION = '6.4.0'
        DEFAULT_BASE_LANG = 'en'
        CONFIG_FILE_NAME = 'swiftgen-stringtypes.yml'

        attr_reader :install_path
        attr_reader :version

        # @param [String] install_path The path to install SwiftGen to. Usually something like "#{PROJECT_DIR}/vendor/swiftgen/#{SWIFTGEN_VERSION}".
        #        It's recommended to provide an absolute path here rather than a relative one, to ensure it's not dependant on where the action is run from.
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
          return false unless File.exists?(swiftgen_bin)
          vers_string = `#{swiftgen_bin} --version`
          # SwiftGen v6.4.0 (Stencil v0.13.1, StencilSwiftKit v2.7.2, SwiftGenKit v6.4.0)
          return vers_string.include?("SwiftGen v#{version}")
        rescue
          return false
        end

        # Download the ZIP of SwiftGen for the requested `version` and install it in the `install_path`
        #
        # @warning This action nukes anything at `install_path` – if something already exists – prior to install SwiftGen there
        #
        def install_swiftgen!
          UI.message "Installing SwiftGen #{version} into #{install_path}"
          Dir.mktmpdir do |tmpdir|
            zipfile = File.join(tmpdir, "swiftgen-#{version}.zip")
            Action.sh('curl', '--fail', '--location', '-o', zipfile, "https://github.com/SwiftGen/SwiftGen/releases/download/#{version}/swiftgen-#{version}.zip")
            extracted_dir = File.join(tmpdir, "swiftgen-#{version}")
            Action.sh('unzip', zipfile, '-d', extracted_dir)

            FileUtils.rm_rf(install_path) if File.exists?(install_path)
            FileUtils.mkdir_p(install_path)
            FileUtils.cp_r("#{extracted_dir}/.", install_path)
          end
        end

        # Install SwiftGen if necessary (if not installed yet with the expected version), then run the checks and returns the violations found, if any
        #
        # @param [String] input_dir The path (ideally absolute) to the directory containing the `.lproj` folders to parse
        # @param [String] base_lang The code name (i.e the basename of one of the `.lproj` folders) of the locale to use as the baseline
        # @return [Hash<String, String>] A hash whose keys are the language codes (basename of `.lproj` folders) for which violations were found,
        #         and the values are the output of the `diff` showing these violations.
        #
        def run(input_dir:, base_lang: DEFAULT_BASE_LANG)
          check_swiftgen_installed || install_swiftgen!
          find_diffs(input_dir: input_dir, base_lang: base_lang)
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
          "{{string.key}}" => [{{string.types|join:","}}]
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
        def generate_swiftgen_config!(input_dir, output_dir)
          # Create the template file
          template_path = File.absolute_path(File.join(output_dir, 'strings-types.stencil'))
          File.write(template_path, template_content)

          # Dynamically create a SwiftGen config which will cover all supported languages
          langs = Dir.chdir(input_dir) do
              Dir.glob('*.lproj').map { |dir| File.basename(dir, '.lproj') }
          end.sort
      
          config = {
            'input_dir' => input_dir,
            'output_dir' => output_dir,
            'strings' => langs.map do |lang|
              {
                  'inputs' => ["#{lang}.lproj/Localizable.strings"],
                  'options' => { 'separator' => "____" }, # Choose an unlikely one to avoid creating needlessly complex Stencil Context due to '.' in sentences sued as keys
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
      
          return [config_file, langs]
        end

        # Because we use English copy verbatim as key names, some keys are the same just except for the upper/lowercase.
        # We need to sort the output again because SwiftGen only sort case-insensitively so that means keys that are
        # the same except case might be in swapped order for different outputs
        #
        # @param [String] dir The temporary directory in which the file to sort lines for is located
        # @param [String] lang The code for the locale we need to sort the output lines for
        #
        def sort_file_lines!(dir, lang)
          file = File.join(dir, output_filename(lang))
          sorted_lines = File.readlines(file).sort
          File.write(file, sorted_lines.join)
          return file
        end

        # Prepares the template and config files, then run SwiftGen, run `diff` on each generated output against the baseline, and returns a Hash of the violations found.
        #
        # @param [String] input_dir The directory where the `.lproj` folders to scan are located
        # @param [String] base_lang The base language used as source of truth that all other languages will be compared against
        # @return [Hash<String, String>] A hash of violations, keyed by language code, whose values are the diff output.
        #
        # @note The returned Hash contains keys only for locales with violations. Locales parsed but without any violations found will not appear in the resulting hash.
        #
        def find_diffs(input_dir:, base_lang:)
          Dir.mktmpdir('a8c-lint-translations-') do |tmpdir|
            # Run SwiftGen 
            (config_file, langs) = generate_swiftgen_config!(input_dir, tmpdir)
            Action.sh(swiftgen_bin, 'config', 'run', '--config', config_file)
            
            # Run diffs
            base_file = sort_file_lines!(tmpdir, base_lang)
            langs.delete(base_lang)
            return Hash[langs.map do |lang|
              file = sort_file_lines!(tmpdir, lang)
              diff = `diff -U0 "#{base_file}" "#{file}"`
              diff.gsub!(/^(---|\+\+\+).*\n/, '')
              diff.empty? ? nil : [lang, diff]
            end.compact]
          end
        end

      end
    end
end
