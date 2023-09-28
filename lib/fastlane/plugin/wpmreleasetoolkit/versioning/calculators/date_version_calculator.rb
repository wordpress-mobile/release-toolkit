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

        # Calculate the previous date-based release version.
        #
        # If the minor version is 1 (indicating the first release of the year), the method prompts
        # the user to input the minor number of the previous release. Otherwise, it calculates the
        # previous minor version. The major version is adjusted accordingly, and the patch and
        # build number components are reset to zero.
        #
        # @param [AppVersion] version The version to calculate the previous date-based release version for.
        #
        # @return [AppVersion] The previous date-based release version.
        #
        def previous_release_version(version:)
          new_version = version.dup
          # Date-based apps start with a minor version of 1 for the first release of the year. We can't assume what the
          # the previous minor number was, so the user needs to input it
          if version.minor == 1
            new_version.major -= 1
            new_version.minor = FastlaneCore::UI.prompt(text: 'Please enter the minor number of the previous release: ')
            new_version.patch = 0
            new_version.build_number = 0

            new_version
          else
            previous_minor_version(version: version)
          end
        end
      end
    end
  end
end
