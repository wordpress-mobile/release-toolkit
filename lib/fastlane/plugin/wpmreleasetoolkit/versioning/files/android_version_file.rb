# A class for reading and writing Android version information to a version.properties file.
require 'java-properties'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class AndroidVersionFile
        attr_reader :version_properties_path

        # Initializes a new instance of AndroidVersionFile with the specified version.properties file path.
        #
        # @param [String] version_properties_path The path to the version.properties file.
        #
        def initialize(version_properties_path:)
          @version_properties_path = version_properties_path
        end

        # Reads the version name from a version.properties file.
        #
        # @return [AppVersion] An instance of `AppVersion` representing the version name read from the file.
        #
        # @raise [UI::Error] If the file_path is nil or the version name is not found.
        #
        def read_version_name
          verify_version_properties_exists

          beta_identifier = AndroidVersionFormatter::BETA_IDENTIFIER

          # Read the version name from the version.properties file
          file_content = JavaProperties.load(version_properties_path)
          version_name = file_content[:versionName]

          UI.user_error!('Version name not found in version.properties') if version_name.nil?

          # Set the build number to 0 by default so that it will be set correctly for non-beta version numbers
          build_number = 0

          if version_name.include?(beta_identifier)
            # Extract the build number from the version name
            build_number = version_name.split('-')[2]
            # Extract the version name without the build number and drop the RC suffix
            version_name = version_name.split(beta_identifier)[0]
          end

          # Split the version name into its components
          version_number_parts = version_name.split('.').map(&:to_i)
          # Fill the array with 0 if needed to ensure array has at least 3 components
          version_number_parts.fill(0, version_number_parts.length...3)

          # Map version_number_parts to AppVersion model
          major = version_number_parts[0]
          minor = version_number_parts[1]
          patch = version_number_parts[2]

          # Create an AppVersion object
          Fastlane::Models::AppVersion.new(major, minor, patch, build_number)
        end

        # Reads the version code from a version.properties file.
        #
        # @param file_path [String] The path to the version.properties file.
        #
        # @return [BuildCode] An instance of `BuildCode` representing the version code read from the file.
        #
        # @raise [UI::Error] If the file_path is nil or the version code is not found.
        #
        def read_version_code
          verify_version_properties_exists

          UI.user_error!("version.properties #{version_properties_path} not found") unless File.exist?(version_properties_path)

          # Read the version code from the version.properties file
          file_content = JavaProperties.load(version_properties_path)
          version_code = file_content[:versionCode]

          UI.user_error!('Version code not found in version.properties') if version_code.nil?

          # Create a BuildCode object
          Fastlane::Models::BuildCode.new(version_code.to_i)
        end

        # Writes the provided version name and version code to the version.properties file.
        #
        # @param version_name [String] The version name to write to the file.
        # @param version_code [String] The version code to write to the file.
        #
        # @raise [UI::Error] If the version name or version code is nil.
        #
        def write_version(version_name, version_code)
          verify_version_properties_exists

          # Create the version name and version code hash
          version = {
            versionName: version_name,
            versionCode: version_code
          }

          # Write the version name and version code hash to the version.properties file
          JavaProperties.write(
            version,
            version_properties_path
          )
        end

        # Verifies the existence of the version.properties file.
        #
        # @raise [UI.user_error] Raised if the version.properties file does not exist.
        #
        def verify_version_properties_exists
          UI.user_error!("version.properties #{version_properties_path} not found") unless File.exist?(version_properties_path)
        end
      end
    end
  end
end
