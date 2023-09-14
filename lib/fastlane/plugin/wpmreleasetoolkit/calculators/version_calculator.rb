require_relative '../models/app_version'

module Fastlane
  module Calculators
    class VersionCalculator
      def initialize(version)
        @version = version
      end

      # Derive the next major version from this version number
      def calculate_next_major_version
        @version.major += 1
        @version.minor = 0
        @version.patch = 0
        @version.build_number = 0

        @version
      end

      # Derive the next minor version from this version number
      def calculate_next_minor_version
        @version.minor += 1
        @version.patch = 0
        @version.build_number = 0

        @version
      end

      # Derive the next patch version from this version number
      def calculate_next_patch_version
        @version.patch += 1
        @version.build_number = 0

        @version
      end

      # Derive the next build number from this version number
      def calculate_next_build_number
        @version.build_number += 1

        @version
      end

      def today_date
        DateTime.now.strftime('%Y%m%d')
      end

      def calculate_next_internal_version
        @version.build_number = today_date

        @version
      end

      # Is this version number a patch version?
      def patch?
        !@version.patch.zero?
      end

      def calculate_previous_major_version
        @version.minor -= 1

        @version
      end

      def calculate_previous_minor_version
        @version.minor -= 1

        @version
      end

      def calculate_previous_patch_version
        @version.patch -= 1 unless @version.patch.zero?

        @version
      end

      def calculate_previous_build_number
        @version.build_number -= 1

        @version
      end
    end
  end
end
