require_relative '../models/app_version'
require_relative 'version_bumper'

module Fastlane
  module Bumpers
    class MarketingVersionBumper < VersionBumper
      def bump_minor_version
        @version.minor == 9 ? bump_major_version : super

        @version
      end
    end
  end
end
