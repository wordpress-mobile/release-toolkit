require_relative '../models/app_version'
require_relative 'version_calculator'

module Fastlane
  module Calculators
    class MarketingVersionCalculator < VersionCalculator
      def calculate_next_release_version
        @version.minor == 9 ? calculate_next_major_version : calculate_next_minor_version

        @version
      end

      def calculate_previous_release_version
        if @version.minor.zero?
          @version.major = calculate_previous_major_version
          @version.minor = 9
        else
          calculate_previous_minor_version
        end

        @version.patch = 0
        @version.build_number = 0

        @version
      end
    end
  end
end
