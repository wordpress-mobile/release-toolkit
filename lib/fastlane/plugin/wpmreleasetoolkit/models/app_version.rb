module Fastlane
  module Models
    # The AppVersion model represents a version of an app with major, minor, patch, and build number components.
    class AppVersion
      attr_accessor :major, :minor, :patch, :build_number

      # Initializes a new AppVersion instance.
      #
      # @param [Integer] major The major version number.
      # @param [Integer] minor The minor version number.
      # @param [Integer] patch The patch version number.
      # @param [Integer] build_number The build number.
      #
      def initialize(major, minor, patch = 0, build_number = 0)
        # Validate that the major and minor version numbers are not nil
        UI.user_error!('Major version cannot be nil') if major.nil?
        UI.user_error!('Minor version cannot be nil') if minor.nil?

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
