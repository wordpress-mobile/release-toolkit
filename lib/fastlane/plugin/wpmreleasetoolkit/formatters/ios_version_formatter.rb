require_relative '../models/app_version'
require_relative 'version_formatter'
require_relative '../calculators/version_calculator'

module Fastlane
  module Formatters
    class IosVersionFormatter < VersionFormatter
      def beta_version
        @version
      end

      def internal_version
        Fastlane::Calculators::VersionCalculator.new(@version).calculate_next_internal_version

        "#{@version.major}.#{@version.minor}.#{@version.patch}.#{@version.build_number}"
      end
    end
  end
end
