require_relative '../models/app_version'
require_relative '../calculators/version_calculator'

module Fastlane
  module Formatters
    class VersionFormatter
      ALPHA_IDENTIFIER = 'alpha'
      BETA_IDENTIFIER = 'RC'

      def initialize(version)
        @version = version
      end

      def release_version
        @version.patch.zero? ? "#{@version.major}.#{@version.minor}" : "#{@version.major}.#{@version.minor}.#{@version.patch}"
      end
    end
  end
end
