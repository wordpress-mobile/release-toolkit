require 'java-properties'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `AndroidVersionFile` class takes in a version.properties file path and reads/writes values to/from the file.
      class AndroidVersionFile
        attr_reader :version_properties_path

        # Initializes a new instance of AndroidVersionFile with the specified version.properties file path.
        #
        # @param [String] version_properties_path The path to the version.properties file.
        #
        def initialize(version_properties_path: 'version.properties')
          UI.user_error!("version.properties not found at this path: #{version_properties_path}") unless File.exist?(version_properties_path)

          @version_properties_path = version_properties_path
        end

        # Reads the version name from a version.properties file.
        #
        # @return [String] The version name read from the file.
        #
        # @raise [UI::Error] If the file_path is nil or the version name is not found.
        #
        def read_version_name
          # Read the version name from the version.properties file
          file_content = JavaProperties.load(version_properties_path)
          version_name = file_content[:versionName]
          UI.user_error!('Version name not found in version.properties') if version_name.nil?

          version_name
        end

        # Reads the version code from a version.properties file.
        #
        # @param [String] file_path The path to the version.properties file.
        #
        # @return [BuildCode] An instance of `BuildCode` representing the version code read from the file.
        #
        # @raise [UI::Error] If the file_path is nil or the version code is not found.
        #
        def read_version_code
          # Read the version code from the version.properties file
          file_content = JavaProperties.load(version_properties_path)
          version_code = file_content[:versionCode]
          UI.user_error!('Version code not found in version.properties') if version_code.nil?

          # Create a BuildCode object
          Fastlane::Models::BuildCode.new(version_code.to_i)
        end

        # Writes the provided version name and version code to the version.properties file.
        #
        # @param [String] version_name The version name to write to the file.
        # @param [String] version_code The version code to write to the file.
        #
        # @raise [UI::Error] If the version name or version code is nil.
        #
        def write_version(version_name, version_code)
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
      end
    end
  end
end
