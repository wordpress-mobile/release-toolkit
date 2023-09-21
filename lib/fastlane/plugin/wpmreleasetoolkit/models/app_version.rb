# Fastlane::Models::AppVersion represents a version of an app with major, minor, patch, and build number components.

module Fastlane
  module Models
    class AppVersion
      attr_accessor :major, :minor, :patch, :build_number

      # Initializes a new AppVersion instance.
      #
      # @param major [Integer] the major version number.
      # @param minor [Integer] the minor version number.
      # @param patch [Integer] the patch version number.
      # @param build_number [Integer] the build number.
      #
      def initialize(major, minor, patch, build_number)
        @major = major
        @minor = minor
        @patch = patch
        @build_number = build_number
      end

      # Converts the AppVersion object to a string representation.
      # This should only be used for internal debugging/testing purposes, not to write versions in version files
      # In order to format an `AppVersion` into a `String`, you should use the appropriate `VersionFormatter` for your project instead.
      #
      # @return [String] a string in the format "major.minor.patch.build_number".
      #
      def to_s
        "#{@major}.#{@minor}.#{@patch}.#{@build_number}"
      end
    end
  end
end
