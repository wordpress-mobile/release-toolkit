# A class for reading and writing Android version information to a version.properties file.
#
require_relative '../../models/app_version'
require_relative '../../models/build_code'
require_relative '../formatters/android_version_formatter'

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
        # @param version_properties_path [String] The path to the version.properties file.
        #
        # @return [AppVersion] An instance of `AppVersion` representing the version name read from the file.
        #
        # @raise [UI::Error] If the file_path is nil or the version name is not found.
        #
        def self.read_version_name_from_version_properties(version_properties_path)
          beta_identifier = Fastlane::Wpmreleasetoolkit::Versioning::AndroidVersionFormatter::BETA_IDENTIFIER

          UI.user_error!("version.properties #{version_properties_path} not found") unless File.exist?(version_properties_path)

          # Read the version name from the version.properties file
          file_content = File.read(version_properties_path)
          version_name = file_content.match(/versionName=(\S*)/m)&.captures&.first

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
        def self.read_version_code_from_version_properties(file_path)
          UI.user_error!("version.properties #{file_path} not found") unless File.exist?(file_path)

          # Read the version code from the version.properties file
          text = File.read(file_path)
          version_code = text.match(/versionCode=(\S*)/m)&.captures&.first

          UI.user_error!('Version code not found in version.properties') if version_code.nil?

          # Create a BuildCode object
          Fastlane::Models::BuildCode.new(version_code.to_i)
        end

        # Writes the version name to a version.properties file.
        #
        # @param file_path [String] The path to the version.properties file.
        #
        # @param version_name [String] The version name to write to the file.
        #
        def self.write_version_name_to_version_properties(file_path, version_name)
          write_value_to_version_properties(
            file_path,
            'versionName',
            version_name
          )
        end

        # Writes the version code to a version.properties file.
        #
        # @param file_path [String] The path to the version.properties file.
        #
        # @param version_code [String] The version code to write to the file.
        #
        def self.write_version_code_to_version_properties(file_path, version_code)
          write_value_to_version_properties(
            file_path,
            'versionCode',
            version_code
          )
        end

        # Writes a key-value pair to a version.properties file.
        #
        # @param file_path [String] The path to the version.properties file.
        #
        # @param key [String] The key for the key-value pair.
        #
        # @param value [String] The value to write to the file.
        #
        # @raise [UI::Error] If the file_path doesn't exist.
        #
        def self.write_value_to_version_properties(file_path, key, value)
          UI.user_error!("version.properties #{file_path} not found") unless File.exist?(file_path)

          # Read the contents of the version.properties file
          content = File.read(file_path)
          # Replace the value in the version.properties file
          content.gsub!(/#{key}=(\S*)/, "#{key}=#{value}")
          File.write(file_path, content)
        end
      end
    end
  end
end
