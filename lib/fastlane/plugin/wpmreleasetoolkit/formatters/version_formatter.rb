require_relative '../models/version'

module Fastlane
  module Formatter
    class VersionFormatter
      def initialize(version)
        @version = version
      end

      def release_version
        [version.major, version.minor].join('.') if version.patch.zero? && version.rc.nil?
      end

      def hotfix_version
        [version.major, version.minor, version.patch].join('.') if !version.patch.zero? && version.rc.nil?
      end
    end
  end
end
