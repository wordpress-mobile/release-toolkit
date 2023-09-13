require_relative '../models/app_version'
require_relative 'version_calculator'

module Fastlane
  module Calculators
    class MarketingVersionCalculator < VersionCalculator
      def bump_minor_version
        @version.minor == 9 ? bump_major_version : super

        @version
      end
    end
  end
end
