# The `DateVersionCalculator` class is a specialized version calculator for date-based versions
# of an app, extending the `VersionCalculator` class.
require 'fastlane'
require_relative '../../models/app_version'
require_relative 'version_calculator'

module WPMReleaseToolkit
  module Versioning
    class DateVersionCalculator < VersionCalculator
      # Calculate the next date-based release version.
      #
      # If the current month is December, the method prompts the user to determine if the next
      # release will be the first release of the next year. If so, it increments the major version
      # and sets the minor version to 1, resetting the patch and build number components to zero.
      # Otherwise, it calculates the next minor version.
      #
      # @return [AppVersion] The next date-based release version.
      #
      def calculate_next_release_version
        first_release_of_year = FastlaneCore::UI.confirm('Is this release the first release of next year?') if Time.now.month == 12
        if first_release_of_year
          @version.major += 1
          @version.minor = 1
          @version.patch = 0
          @version.build_number = 0
        else
          calculate_next_minor_version
        end

        @version
      end

      # Calculate the previous date-based release version.
      #
      # If the minor version is 1 (indicating the first release of the year), the method prompts
      # the user to input the minor number of the previous release. Otherwise, it calculates the
      # previous minor version. The major version is adjusted accordingly, and the patch and
      # build number components are reset to zero.
      #
      # @return [AppVersion] The previous date-based release version.
      #
      def calculate_previous_release_version
        # Date-based apps start with a minor version of 1 for the first release of the year. We can't assume what the
        # the previous minor number was, so the user needs to input it
        if @version.minor == 1
          minor_number = prompt(text: 'Please enter the minor number of the previous release: ')
          @version.major = previous_major_version
          @version.minor = minor_number
          @version.patch = 0
          @version.build_number = 0
        else
          previous_minor_version
        end

        @version
      end
    end
  end
end
