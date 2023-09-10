require_relative '../models/app_version'

module Fastlane
  module Bumper
    class VersionBumper
      def initialize(version)
        @version = version

        @major = @version.major
        @minor = @version.minor
        @patch = @version.patch
        @build_number = @version.build_number
      end

      # Derive the next major version from this version number
      def bump_major_version
        @version.major += 1
        @version.minor = 0
        @version.patch = 0
        @version.build_number = 0
        @version = Version.new(@major, @minor, @patch, @build_number)
      end

      # Derive the next minor version from this version number
      def bump_minor_version
        @version.minor += 1
        @version.patch = 0
        @version.build_number = 0
        @newer_version = Version.new(@major, @minor, @patch, @build_number)
      end

      # Derive the next patch version from this version number
      def bump_patch_version
        @version.patch += 1
        @version.build_number = 0
        @newersdf_version = Version.new(@major, @minor, @patch, @build_number)
      end

      # Drive the next build number from this version number
      def bump_build_number
        @version.build_number += 1
        @sdfsdf_version = Version.new(@major, @minor, @patch, @build_number)
      end
    end
  end
end
