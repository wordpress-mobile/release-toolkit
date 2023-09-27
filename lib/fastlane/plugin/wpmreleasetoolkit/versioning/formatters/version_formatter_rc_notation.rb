# The `RCNotationVersionFormatter` class extends the `VersionFormatter` class. It is a specialized version
# formatter for apps that may use versions in the format of `1.2.3-rc-4`.
require_relative 'version_formatter_abstract'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class RCNotationVersionFormatter < VersionFormatterAbstract
        # The string identifier used for beta versions in Android.
        RC_SUFFIX = 'rc'.freeze

        # Parse the version string into an AppVersion instance
        #
        # @param version_name [String] The version string to parse
        #
        # @return [AppVersion] The parsed version
        #
        def parse(version_name)
          # Set the build number to 0 by default so that it will be set correctly for non-beta version numbers
          build_number = 0

          if version_name.include?(RC_SUFFIX)
            # Extract the build number from the version name
            build_number = version_name.split('-')[2].to_i
            # Extract the version name without the build number and drop the RC suffix
            version_name = version_name.split(RC_SUFFIX)[0]
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

        # Get the formatted beta version of the Android app
        #
        # This method constructs a beta version string by combining the release version
        # with the beta identifier and the build number. It ensures that the build number is
        # 1 or higher, as beta versions must have a build number greater than or equal to 1.
        #
        # @param version [AppVersion] The version object to format
        #
        # @return [String] The formatted beta version of the Android app
        #
        # @raise [UI::Error] If the build number of the beta version is not 1 or higher
        #
        def beta_version(version)
          # Ensure that the build number is 1 or higher for a beta version
          UI.user_error!('The build number of a beta version must be 1 or higher') unless version.build_number.positive?

          # Construct and return the formatted beta version string.
          "#{release_version(version)}-#{RC_SUFFIX}-#{version.build_number}"
        end
      end
    end
  end
end
