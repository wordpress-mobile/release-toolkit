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

        # @param [String] install_path The path to install SwiftGen to. Usually something like "#{PROJECT_DIR}/vendor/swiftgen"
        def initialize(install_path:, version: SWIFTGEN_VERSION)
          @install_path = install_path
          @version = version || SWIFTGEN_VERSION
        end

        def check_swiftgen_installed
          return false unless File.exists?(swiftgen_bin)
          vers_string = `#{swiftgen_bin} --version`
          # SwiftGen v6.4.0 (Stencil v0.13.1, StencilSwiftKit v2.7.2, SwiftGenKit v6.4.0)
          return vers_string.include?("SwiftGen v#{version}")
        rescue
          return false
        end

        def install_swiftgen
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

        def run(input_dir:, base_lang: DEFAULT_BASE_LANG)
          check_swiftgen_installed || install_swiftgen
          find_diffs(input_dir: input_dir, base_lang: base_lang)
        end

        ##################

        private
        
        def swiftgen_bin
          "#{install_path}/bin/swiftgen"
        end

        def output_filename(lang)
          "L10nParamsList.#{lang}.txt"
        end
        
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

        # @return [(String, Array<String>)] A tuple of (config_file_absolute_path, Array<langs>)
        #
        def generate_swiftgen_config(input_dir, output_dir)
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
        def sort_file_lines!(dir, lang)
          file = File.join(dir, output_filename(lang))
          sorted_lines = File.readlines(file).sort
          File.write(file, sorted_lines.join)
          return file
        end

        # @param [String] input_dir The directory where the `.lproj` folders to scan are located
        # @param [String] base_lang The base language used as source of truth that all other languages will be compared against
        # @return [Hash<String, String>] A hash of violations, keyed by language code, whose values are the diff result or nil if no diff
        #
        def find_diffs(input_dir:, base_lang:)
          Dir.mktmpdir('a8c-lint-translations-') do |tmpdir|
            # Run SwiftGen
            (config_file, langs) = generate_swiftgen_config(input_dir, tmpdir)
            Action.sh(swiftgen_bin, 'config', 'run', '--config', config_file)
            
            # Run diffs
            base_file = sort_file_lines!(tmpdir, base_lang)
            langs.delete(base_lang)
            return Hash[langs.map do |lang|
              file = sort_file_lines!(tmpdir, lang)
              diff = `diff -U0 "#{base_file}" "#{file}"`
              diff.gsub!(/^(---|\+\+\+).*\n/, '')
              diff.empty? ? nil : [lang, diff]
              # UI.puts "### '#{lang}' vs '#{base_lang}' base\n\n#{diff}\n" unless diff.empty?
            end]
          end
        end

      end
    end
end
