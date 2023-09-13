require_relative '../models/app_version'
require_relative 'version_formatter'

module Fastlane
  module Formatters
    class IosVersionFormatter < VersionFormatter
      def beta_version
        @version
      end
    end
  end
end
