require_relative '../models/app_version'

module Fastlane
  module Formatters
    class VersionFormatter
      def initialize(version)
        @version = version
      end

      def release_version
        @version.patch.zero? ? "#{@version.major}.#{@version.minor}" : "#{@version.major}.#{@version.minor}.#{@version.patch}"
      end
    end
  end
end
