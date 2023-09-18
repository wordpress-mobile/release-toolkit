# The `BuildCodeCalculator` class is responsible for performing calculations on build codes.
require_relative '../../models/build_code'

module WPMReleaseToolkit
  module Versioning
    class BuildCodeCalculator
      # Initializes a new BuildCodeCalculator instance with a given build code.
      #
      # @param build_code [BuildCode] The build code to perform calculations on.
      #
      def initialize(build_code)
        @build_code = build_code
      end

      # Calculate the next build code.
      #
      # This method increments the build code value by 1.
      #
      # @return [BuildCode] The next build code.
      #
      def calculate_next_build_code
        @build_code.build_code += 1

        @build_code
      end
    end
  end
end
