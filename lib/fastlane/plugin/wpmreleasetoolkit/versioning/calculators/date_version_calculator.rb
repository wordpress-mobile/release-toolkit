# The `DateVersionCalculator` class is a specialized version calculator for date-based versions
# of an app, extending the `VersionCalculator` class.
require_relative 'version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class DateVersionCalculator < VersionCalculator
        # Calculate the next date-based release version.
        #
        # If the current month is December, the method prompts the user to determine if the next
        # release will be the first release of the next year. If so, it increments the major version
        # and sets the minor version to 1, resetting the patch and build number components to zero.
        # Otherwise, it calculates the next minor version.
        #
        # @param after [AppVersion] The version to calculate the next date-based release version for.
        #
        # @return [AppVersion] The next date-based release version.
        #
        def next_release_version(after:)
          first_release_of_year = FastlaneCore::UI.confirm('Is this release the first release of next year?') if Time.now.month == 12
          if first_release_of_year
            after.major += 1
            after.minor = 1
            after.patch = 0
            after.build_number = 0
          else
            next_minor_version(after: after)
          end

          after
        end

        # Calculate the previous date-based release version.
        #
        # If the minor version is 1 (indicating the first release of the year), the method prompts
        # the user to input the minor number of the previous release. Otherwise, it calculates the
        # previous minor version. The major version is adjusted accordingly, and the patch and
        # build number components are reset to zero.
        #
        # @param before [AppVersion] The version to calculate the previous date-based release version for.
        #
        # @return [AppVersion] The previous date-based release version.
        #
        def previous_release_version(before:)
          # Date-based apps start with a minor version of 1 for the first release of the year. We can't assume what the
          # the previous minor number was, so the user needs to input it
          if before.minor == 1
            minor_number = FastlaneCore::UI.prompt(text: 'Please enter the minor number of the previous release: ')
            before.major -= 1
            before.minor = minor_number
            before.patch = 0
            before.build_number = 0
          else
            previous_minor_version(before: before)
          end

          before
        end
      end
    end
  end
end
