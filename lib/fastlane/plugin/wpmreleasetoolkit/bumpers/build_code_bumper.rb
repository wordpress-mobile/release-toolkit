require_relative '../models/build_code'

module Fastlane
  module Bumpers
    class BuildCodeBumper
      def initialize(build_code)
        @build_code = build_code
      end

      def bump_build_code
        @build_code.build_code += 1

        @build_code
      end
    end
  end
end
