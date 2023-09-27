# The `MarketingVersionCalculator` class is a specialized version calculator for marketing versions
# of an app, extending the `VersionCalculatorAbstract` class. It provides methods to calculate the next and previous
# marketing release versions.
require_relative 'version_calculator_abstract'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class MarketingVersionCalculator < VersionCalculatorAbstract
        # Calculate the next marketing release version.
        #
        # This method checks if the minor version is 9. If it is, it calculates the next major version.
        # Otherwise, it calculates the next minor version. The patch and build number components are reset to zero.
        #
        # @param version [AppVersion] The version to calculate the next marketing release version for.
        #
        # @return [AppVersion] The next marketing release version.
        #
        def next_release_version(version:)
          UI.user_error!('Marketing Versioning: The minor version cannot be greater than 9') if version.minor > 9

          version.minor == 9 ? next_major_version(version: version) : next_minor_version(version: version)

          version
        end

        # Calculate the previous marketing release version.
        #
        # If the minor version is zero, it calculates the previous major version and sets the minor
        # version to 9. Otherwise, it calculates the previous minor version. The patch and build number
        # components are reset to zero.
        #
        # @param version [AppVersion] The version to calculate the previous marketing release version for.
        #
        # @return [AppVersion] The previous marketing release version.
        #
        def previous_release_version(version:)
          if version.minor.zero?
            version.major -= 1
            version.minor = 9
          else
            previous_minor_version(version: version)
          end

          version.patch = 0
          version.build_number = 0

          version
        end
      end
    end
  end
end
