require_relative '../models/app_version'

module Fastlane
  module Helper
    class VersionHelper
      def initialize(version)
        @version = version
      end
    end
  end
end
