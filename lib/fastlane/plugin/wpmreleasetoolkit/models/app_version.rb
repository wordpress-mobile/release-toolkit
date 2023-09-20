# Fastlane::Models::AppVersion represents a version of an app with major, minor, patch, and build number components.

module Fastlane
  module Models
    class AppVersion
      attr_accessor :major, :minor, :patch, :build_number

      # Initializes a new AppVersion instance.
      #
      # @param params [String, Array<#to_i>, *#to_i]
      #   - If passed a `String`, it will be split using `.` and each of the resulting 4 components will be converted to integers.
      #   - If passed an `Array`, or a list of more than one parameters, each element will be converted to integers.
      #     Then the 4 resulting elements will serve as major, minor, patch, and build_number values of the AppVersion.
      #
      # @example
      #   # Initialize with a string
      #   version = AppVersion.new('1.2.3.4')
      #
      #   # Initialize with an array
      #   version = AppVersion.new([1, 2, 3, 4])
      #
      def initialize(*params)
        # If a single parameter of type String is passed, split it into components
        params = params.first.split('.') if params.first.is_a?(String)
        # If a single parameter of type Array is passed, make it as if values of the array are passed individually
        params = *params if params.first.is_a?(Array)

        # At that point `params` is an array of the 4 components of the version
        @major, @minor, @patch, @build_number = params.map(&:to_i)
      end

      # Converts the AppVersion object to a string representation.
      #
      # @return [String] a string in the format "major.minor.patch.build_number".
      #
      def to_s
        "#{@major}.#{@minor}.#{@patch}.#{@build_number}"
      end
    end
  end
end
