require_relative 'abstract_version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `DateVersionCalculator` class is a specialized version calculator for date-based versions
      # of an app, extending the `AbstractVersionCalculator` class.
      class DateVersionCalculator < AbstractVersionCalculator
        # Calculate the next date-based release version.
        #
        # If the current month is December, the method prompts the user to determine if the next
        # release will be the first release of the next year. If so, it increments the major version
        # and sets the minor version to 1, resetting the patch and build number components to zero.
        # Otherwise, it calculates the next minor version.
        #
        # @param [AppVersion] version The version to calculate the next date-based release version for.
        #
        # @return [AppVersion] The next date-based release version.
        #
        def next_release_version(version:)
          new_version = version.dup
          first_release_of_year = FastlaneCore::UI.confirm('Is this release the first release of next year?') if Time.now.month == 12
          if first_release_of_year
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
