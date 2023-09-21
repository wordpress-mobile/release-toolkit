# The `MarketingVersionCalculator` class is a specialized version calculator for marketing versions
# of an app, extending the `VersionCalculator` class. It provides methods to calculate the next and previous
# marketing release versions.
require_relative 'version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class MarketingVersionCalculator < VersionCalculator
        # Calculate the next marketing release version.
        #
        # This method checks if the minor version is 9. If it is, it calculates the next major version.
        # Otherwise, it calculates the next minor version. The patch and build number components are reset to zero.
        #
        # @param after [AppVersion] The version to calculate the next marketing release version for.
        #
        # @return [AppVersion] The next marketing release version.
        #
        def next_release_version(after:)
          after.minor == 9 ? next_major_version(after: after) : next_minor_version(after: after)

          after
        end

        # Calculate the previous marketing release version.
        #
        # If the minor version is zero, it calculates the previous major version and sets the minor
        # version to 9. Otherwise, it calculates the previous minor version. The patch and build number
        # components are reset to zero.
        #
        # @param before [AppVersion] The version to calculate the previous marketing release version for.
        #
        # @return [AppVersion] The previous marketing release version.
        #
        def previous_release_version(before:)
          if before.minor.zero?
            before.major -= 1
            before.minor = 9
          else
            previous_minor_version(before: before)
          end

          before.patch = 0
          before.build_number = 0

          before
        end
      end
    end
  end
end
