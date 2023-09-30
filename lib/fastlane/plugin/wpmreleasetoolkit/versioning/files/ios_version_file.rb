require 'xcodeproj'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `IOSVersionFile` class takes in an .xcconfig file path and reads/writes values to/from the file.
      class IOSVersionFile
        attr_reader :xcconfig_path

        # Initializes a new instance of IOSVersionFile with the specified .xcconfig file path.
        #
        # @param [String] xcconfig_path The path to the .xcconfig file.
        #
        def initialize(xcconfig_path:)
          UI.user_error!(".xcconfig file not found at this path: #{xcconfig_path}") unless File.exist?(xcconfig_path)

          @xcconfig_path = xcconfig_path
        end

        # Reads the release version from the .xcconfig file and returns it as a String.
        #
        # @return [String] The release version.
        #
        def read_release_version
          config = Xcodeproj::Config.new(xcconfig_path)
          config.attributes['VERSION_SHORT']
        end

        # Reads the build code from the .xcconfig file and returns it String.
        #
        # Some apps store the build code in the VERSION_LONG attribute, while others store it in the BUILD_NUMBER attribute.
        #
        # @param [String] attribute_name The name of the attribute to read.
        #
        # @return [String] The build code.
        #
        def read_build_code(attribute_name:)
          UI.user_error!('attribute_name must be `VERSION_LONG` or `BUILD_NUMBER`') unless attribute_name.eql?('VERSION_LONG') || attribute_name.eql?('BUILD_NUMBER')

          config = Xcodeproj::Config.new(xcconfig_path)
          config.attributes[attribute_name]
        end

        # Writes the provided version numbers to the .xcconfig file.
        #
        # @param [String, nil] version_short The short version string (optional).
        # @param [String, nil] version_long The long version string (optional).
        # @param [String, nil] build_number The build number (optional).
        #
        # version_long is optional because there are times when it won't be updated, such as a new beta build.
        # version_short is optional because some apps (such as Day One iOS/Mac or Simplenote Mac) don't use it.
        # build_number is optional because some apps (such as WP/JP iOS or WCiOS) don't use it.
        #
        def write(version_short: nil, version_long: nil, build_number: nil)
          config = Xcodeproj::Config.new(xcconfig_path)
          config.attributes['VERSION_SHORT'] = version_short.to_s unless version_short.nil?
          config.attributes['VERSION_LONG'] = version_long.to_s unless version_long.nil?
          config.attributes['BUILD_NUMBER'] = build_number.to_s unless build_number.nil?
          config.save_as(Pathname.new(xcconfig_path))
        end
      end
    end
  end
end
