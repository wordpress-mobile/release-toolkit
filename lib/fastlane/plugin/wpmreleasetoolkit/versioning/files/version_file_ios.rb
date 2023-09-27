# A class for reading and writing version information to an Xcode .xcconfig file.
require 'xcodeproj'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
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

        # Reads the app version from the .xcconfig file and returns it as a String.
        #
        # @return [String] The app version.
        #
        def read_app_version
          config = Xcodeproj::Config.new(xcconfig_path)
          config.attributes['VERSION_LONG']
        end

        # Reads the build code from the .xcconfig file and returns it String.
        #
        # @return [BuildCode] A BuildCode object.
        #
        def read_build_code
          config = Xcodeproj::Config.new(xcconfig_path)
          build_code = config.attributes['BUILD_NUMBER']

          Fastlane::Models::BuildCode.new(build_code)
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
