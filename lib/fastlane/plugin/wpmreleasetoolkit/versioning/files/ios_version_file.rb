# A class for reading and writing version information to an Xcode .xcconfig file.
#
require 'xcodeproj'
require_relative '../../models/app_version'
require_relative '../../models/build_code'

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
          @xcconfig_path = xcconfig_path
        end

        # Reads the app version from the .xcconfig file and returns it as an AppVersion object.
        #
        # @return [Fastlane::Models::AppVersion] The app version.
        #
        def read_app_version
          verify_xcconfig_exists

          config = Xcodeproj::Config.new(xcconfig_path)
          version = config.attributes['VERSION_LONG']
          parts = version.split('.').map(&:to_i)
          Fastlane::Models::AppVersion.new(*parts)
        end

        # Reads the build code from the .xcconfig file and returns it as a BuildCode object.
        #
        # @return [Fastlane::Models::BuildCode] The build code.
        #
        def read_build_code
          verify_xcconfig_exists

          config = Xcodeproj::Config.new(xcconfig_path)
          number = config.attributes['BUILD_NUMBER']
          Fastlane::Models::BuildCode.new(number)
        end

        # Writes the provided version numbers to the .xcconfig file.
        #
        # @param [String] version_short The short version string.
        # @param [String, nil] version_long The long version string (optional).
        # @param [String, nil] build_number The build number (optional).
        #
        # version_short is optional because some apps (such as Day One iOS/Mac or Simplenote Mac) don't use it.
        # build_number is optional because some apps (such as WP/JP iOS or WCiOS) don't use it.
        #
        def write(version_short:, version_long: nil, build_number: nil)
          verify_xcconfig_exists

          config = Xcodeproj::Config.new(xcconfig_path)
          config.attributes['VERSION_SHORT'] = version_short.to_s unless version_short.nil?
          config.attributes['VERSION_LONG'] = version_long.to_s unless version_long.nil?
          config.attributes['BUILD_NUMBER'] = build_number.to_s unless build_number.nil?
          config.save_as(Pathname.new(xcconfig_path))
        end

        # Verifies the existence of the .xcconfig file.
        #
        # @raise [UI.user_error] Raised if the .xcconfig file does not exist.
        def verify_xcconfig_exists
          UI.user_error!(".xcconfig file #{xcconfig_path} not found") unless File.exist?(xcconfig_path)
        end
      end
    end
  end
end
