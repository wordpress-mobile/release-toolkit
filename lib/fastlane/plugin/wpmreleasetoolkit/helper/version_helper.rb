require_relative '../models/app_version'

module Fastlane
  module Helper
    class VersionHelper
      def initialize(version)
        @version = version
      end

      # Is this version number a patch version?
      def patch?
        !version.patch.zero?
      end

      # Is this version number a prerelease version?
      def prerelease?
        !version.rc.nil?
      end
    end
  end
end
