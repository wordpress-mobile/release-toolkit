require_relative '../models/version'

module Fastlane
  module Bumper
    class MarketingVersionBumper < VersionBumper
      # Derive the next minor version from this version number
      def bump_minor_version
        @minor == 9 ? bump_major_version : super
      end
    end
  end
end
