module Fastlane
  module Models
    # The `BuildCode` model represents a build code for an app. This could be the Version Code for an Android app or
    # the VERSION_LONG/BUILD_NUMBER for an iOS/Mac app.
    class BuildCode
      attr_accessor :build_code

      # Initializes a new BuildCode instance with the provided build code value.
      #
      # @param build_code [String] The build code value.
      #
      def initialize(build_code)
        UI.user_error!('Build code cannot be nil') if build_code.nil?

        @build_code = build_code
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
