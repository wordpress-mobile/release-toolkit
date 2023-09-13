require_relative '../models/app_version'

module Fastlane
  module Calculators
    class VersionCalculator
      def initialize(version)
        @version = version
      end

      # Derive the next major version from this version number
      def bump_major_version
        @version.major += 1
        @version.minor = 0
        @version.patch = 0
        @version.build_number = 0

        @version
      end

      # Derive the next minor version from this version number
      def bump_minor_version
        @version.minor += 1
        @version.patch = 0
        @version.build_number = 0

        @version
      end

      # Derive the next patch version from this version number
      def bump_patch_version
        @version.patch += 1
        @version.build_number = 0

        @version
      end

      # Derive the next build number from this version number
      def bump_build_number
        @version.build_number += 1

        @version
      end

      def previous_major_version
        @version.minor -= 1

        @version
      end

      def previous_minor_version
        @version.minor -= 1

        @version
      end

      def previous_patch_version
        @version.patch -= 1

        @version
      end

      def previous_build_number
        @version.build_number -= 1

        @version
      end
    end
  end
end
