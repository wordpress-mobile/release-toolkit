require_relative '../models/app_version'
require_relative 'version_bumper'

module Fastlane
  module Bumpers
    class DateVersionBumper < VersionBumper
      def bump_minor_version
        first_release_of_year = UI.confirm('Is this release the first release of next year?') if Time.now.month == 12
        if first_release_of_year
          @version.major += 1
          @version.minor = 1
          @version.patch = 0
          @version.build_number = 0
        else
          super
        end

        @version
      end
    end
  end
end
