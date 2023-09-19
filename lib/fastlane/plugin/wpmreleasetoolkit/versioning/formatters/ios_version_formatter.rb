# The `IOSVersionFormatter` class is a specialized version formatter for iOS and Mac apps,
# extending the `VersionFormatter` class.
require_relative '../../models/app_version'
require_relative 'version_formatter'
require_relative '../calculators/version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class IOSVersionFormatter < VersionFormatter
        # Get the beta version of the iOS app
        #
        # @return [AppVersion] The beta-formatted version of the iOS app
        #
        def beta_version(version)
          "#{version.major}.#{version.minor}.#{version.patch}.#{version.build_number}"
        end

        # Calculate and retrieve the internal version of the iOS app
        #
        # This method uses the `VersionCalculator` to calculate the next internal version based on
        # the provided `@version`. The internal version is in the format
        # 'major.minor.patch.build_number', with build number being today's date.
        #
        # @return [AppVersion] The internal version of the iOS app
        #
        def internal_version(version)
          # Create a VersionCalculator instance and calculate the next internal version
          # based on the current `@version`.
          Fastlane::Wpmreleasetoolkit::Versioning::VersionCalculator.new.calculate_next_internal_version(version)

          # Return the calculated version
          "#{version.major}.#{version.minor}.#{version.patch}.#{version.build_number}"
        end
      end
    end
  end
end
