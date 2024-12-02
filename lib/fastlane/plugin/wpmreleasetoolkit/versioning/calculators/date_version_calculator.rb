require_relative 'abstract_version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `DateVersionCalculator` class is a specialized version calculator for date-based versions
      # of an app, extending the `AbstractVersionCalculator` class.
      class DateVersionCalculator < AbstractVersionCalculator
        # Calculate the next date-based release version.
        #
        # When increment_to_next_year is true, increments the major version (representing the year) and resets all other
        # components (minor to 1, patch and build number to 0). Otherwise, calculates the
        # next minor version using the parent class implementation.
        #
        # @param [AppVersion] version The version to calculate the next date-based release version for.
        # @param [Boolean] increment_to_next_year Whether to increment the version to the next year. Defaults to false.
        #
        # @return [AppVersion] The next date-based release version.
        #
        def next_release_version(version:, increment_to_next_year: false)
          if increment_to_next_year
            new_version = version.dup
            new_version.major += 1
            new_version.minor = 1
            new_version.patch = 0
            new_version.build_number = 0

            new_version
          else
            next_minor_version(version: version)
          end
        end
      end
    end
  end
end
