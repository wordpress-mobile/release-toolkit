module ReleaseToolkit
  module Models
    module Android
      # A pair of Version instances going together, one for alpha channel and one for standard channel.
      class VersionSet
        # @return [Hash{Symbol=>Version}]
        attr_reader :flavors

        # @param [Hash{Symbol=>Version}] flavors The hash containing a list of flavors and their corresponding `Version`
        def initialize(**flavors)
          @flavors = flavors || {}
        end

        # @param [Symbol] key The name of the flavor to get the `Version` for
        # @return [Version] The version (name & code) for that flavor
        def [](key)
          flavors[key]
        end

        # Read the various versions by parsing a gradle file
        #
        # @param [String] path The path to the `build.gradle` file to read the versions from.
        #        If nil (the default), will guess it as `<project root>/$PROJECT_NAME/build.gradle`
        # @param [Array(Symbol)] flavors The list of flavors to read from the gradle file
        #
        # @return [VersionSet] A version set containing the flavors found (amongst the ones requested),
        #         associated with their respective `Version` instances ()containing the name and code for that flavor).
        #
        def self.from_gradle_file(path: nil, flavors: [:defaultConfig, :vanilla])
          path ||= default_gradle_path
          current_flavor = nil
          found_versions = {} # Will be a Hash keyed by flavor, with values being a {:name, :code} Hash
          File.readlines(path).each do |line|
            line = line.gsub(%r{//.*$}, '').strip # remove any comment at end of line if any, then trip whitespace from start and end
            # detect sections, aka "word + optional whitespace(s) + '{'" (on the _trimmed_ line)
            if line =~ /^([a-zA-Z]+)\s*\{$/ && flavors.include?(Regexp.last_match(1).to_sym)
              current_flavor = Regexp.last_match(1).to_sym
              found_versions[current_flavor] = {}
            elsif current_flavor && line =~ /^versionName\s+"(.*)"$/
              found_versions[current_flavor][:name] = Regexp.last_match(1)
            elsif current_flavor && line =~ /^versionCode\s+([0-9]*)$/
              found_versions[current_flavor][:code] = Regexp.last_match(1)
            end
          end

          version_map = found_versions.map do |flavor, info|
            version = Version.new(name: info[:name], code: info[:code])
            (version.nil? || version.name.nil? && version.code.nil?) ? nil : [flavor, version]
          end.compact.to_h

          return VersionSet.new(version_map)
        end

        # Update the `build.gradle` file with the values of `versionName` and `versionCode` for each flavor of this `VersionSet`.
        #
        # @param [String] path Path to the `build.gradle` file to update.
        #        If nil (the default), will guess it as `<project root>/$PROJECT_NAME/build.gradle`
        #
        def apply_to_gradle_file(path: nil)
          path ||= self.class.default_gradle_path
          temp_file = Tempfile.new('fastlaneIncrementVersion')
          current_flavor = nil
          updated_keys = []
          File.readlines(path).each do |line|
            strip_line = line.gsub(%r{//.*$}, '').strip # remove any comment at end of line if any, then trip whitespace from start and end
            if strip_line =~ /^([a-zA-Z]+)\s*\{$/ && flavors.keys.include?(Regexp.last_match(1).to_sym)
              current_flavor = Regexp.last_match(1).to_sym
              updated_keys = []
              temp_file.puts line
            elsif current_flavor && strip_line =~ /^versionName\s+"(.*)"$/ && !updated_keys.include?(:name)
              new_value = flavors[current_flavor].name
              temp_file.puts line.gsub(/versionName\s+"(.*)"/, %{versionName "#{new_value}"})
              updated_keys.append(:name)
            elsif current_flavor && strip_line =~ /^versionCode\s+([0-9]+)$/ && !updated_keys.include?(:code)
              new_value = flavors[current_flavor].code
              temp_file.puts line.gsub(/versionCode\s+([0-9]+)/, %{versionCode #{new_value}})
              updated_keys.append(:code)
            else
              temp_file.puts line
            end
          end
          temp_file.close
          FileUtils.mv(temp_file.path, path)
          temp_file.unlink
        end

        # @return [Integer] Maximum value of version codes across all flavors. Useful to find the next value
        def max_version_code
          flavors.values.compact.map(&:code).max
        end

        #########################
        # Private Helpers

        class << self
          # private

          # @return [String] The path to the default `build.gradle`, i.e `$PROJECT_NAME/build.gradle` relative to repo root
          # @env PROJECT_NAME Name of the subdirectory containing the project source, relative to the repo root.
          def default_gradle_path
            UI.user_error!("You need to set the \`PROJECT_NAME\` environment variable to the relative path to the project subfolder name") if ENV['PROJECT_NAME'].nil?
            project_root = `git rev-parse --top-level`
            UI.message('This action is not run from a git repository, so unable to detect the project root. Assuming \`.\` as that is what fastlane uses by default') if project_root.empty?
            File.join(project_root, ENV['PROJECT_NAME'], 'build.gradle')
          end
        end
      end
    end
  end
end
