module Fastlane
  module Models
    class BuildCode
      attr_accessor :build_code

      def initialize(build_code)
        @build_code = build_code
      end

      def to_s
        @build_code.to_s
      end
    end
  end
end
