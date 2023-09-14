require_relative '../models/build_code'

module Fastlane
  module Calculators
    class BuildCodeCalculator
      def initialize(build_code)
        @build_code = build_code
      end

      def calculate_next_build_code
        @build_code.build_code += 1

        @build_code
      end
    end
  end
end
