require_relative '../models/app_version'
require_relative 'version_calculator'

module Fastlane
  module Calculators
    class DateVersionCalculator < VersionCalculator
      def bump_minor_version
        first_release_of_year = UI.confirm('Is this release the first release of next year?') if Time.now.month == 12
        if first_release_of_year
          @version.major += 1
          @version.minor = 1
          @version.patch = 0
          @version.build_number = 0
        else
          super
        end

        @version
      end

      def previous_release_version
        # Date-based apps start with a minor version of 1 for the first release of the year. We can't assume what the
        # the previous minor number was, so the user needs to input it
        if @version.minor == 1
          minor_number = prompt(text: "Please enter the minor number of the previous release: ")
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
