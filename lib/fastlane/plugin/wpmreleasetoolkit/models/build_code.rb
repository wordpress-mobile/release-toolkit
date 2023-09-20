# The `BuildCode` class represents a build code for an app. This could be the Version Code for an Android app or
# the BUILD_NUMBER xcconfig value used by certain iOS or Mac apps.
module Fastlane
  module Models
    class BuildCode
      attr_accessor :build_code

      # Initializes a new BuildCode instance with the provided build code value.
      #
      # @param build_code [String] The build code value.
      #
      def initialize(build_code)
        @build_code = build_code.to_i
      end

      # Returns the build code as a string.
      #
      # @return [String] The build code represented as a string.
      #
      def to_s
        @build_code.to_s
      end
    end
  end
end
