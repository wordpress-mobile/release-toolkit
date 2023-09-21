# The `FourPartVersionFormatter` class  extends the `VersionFormatter` class. It is a specialized version formatter for
# apps that use versions in the format of `1.2.3.4`.
require_relative 'version_formatter'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class FourPartVersionFormatter < VersionFormatter
        # Parse the version string into an AppVersion instance
        #
        # @param version [String] The version string to parse
        #
        # @return [AppVersion] The parsed version
        #
        def parse(version)
          # Split the version string into its components
          components = version.split('.')

          # Ensure that the version string has at least four components
          UI.user_error!("The version string must have four components. This version string has #{components.count} components") unless components.count == 4

          # Create a new AppVersion instance from the version string components
          Fastlane::Models::AppVersion.new(*components.map(&:to_i))
        end

        # Format the beta version of the app
        #
        # @param version [AppVersion] The version object to format
        #
        # @return [String] The beta-formatted version of the iOS app
        #
        def beta_version(version)
          "#{version.major}.#{version.minor}.#{version.patch}.#{version.build_number}"
        end

        # Calculate and retrieve the internal version of the app
        #
        # This method uses the `VersionCalculator` to calculate the next internal version based on
        # the provided `version`. The internal version is in the format
        # 'major.minor.patch.build_number', with build number being today's date.
        #
        # @param version [AppVersion] The version object to format
        #
        # @return [String] The internal-formatted version of the iOS app
        #
        def internal_version(version)
          # Create a VersionCalculator instance and calculate the next internal version
          # based on the current `@version`.
          VersionCalculator.new.next_internal_version(after: version)

          # Return the calculated version
          "#{version.major}.#{version.minor}.#{version.patch}.#{version.build_number}"
        end
      end
    end
  end
end
