module ReleaseToolkit
  module Models
    module Android
      # An Android Version tuple, consisting of a version name and code.
      #
      class Version
        # [VersionName] version name
        attr_reader :name
        # [Integer] version code
        attr_reader :code

        # @param [VersionName, String] name The versionName of this version tuple
        # @param [String, Integer] code The versionCode of this version tuple
        #
        def initialize(name:, code:)
          @name = name.is_a?(VersionName) ? name : VersionName.from_string(name)
          @code = code&.to_i
        end

        # Convenience method similar to `VersionSet.from_gradle_file` but for when you only need the version of a single flavor.
        # @see VersionSet.from_gradle_file
        #
        # @param [String, NilClass] path The path to the project's `build.gradle` file, or `nil` to use the default
        # @param [Symbol, String] flavor The flavor to extract
        #
        # @return [Version, NilClass] The version (name & code) found in the build.gradle file for the requested flavor, or nil if not found.
        #
        def self.from_gradle_file(path: nil, flavor:)
          flavor = flavor.to_sym
          VersionSet.from_gradle_file(path: path, flavors: [flavor])[flavor]
        end
      end
    end
  end
end
