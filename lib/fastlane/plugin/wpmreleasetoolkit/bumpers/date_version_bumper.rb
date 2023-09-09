require_relative '../models/version'

module Fastlane
  module Bumper
    class DateVersionBumper < VersionBumper
      def bump_minor_version
        first_release_of_year = FastlaneCore::UI.confirm('Is this release the first release of next year?') if Time.now.month == 12
        if first_release_of_year
          @version.major += 1
          @version.minor = 1
          @version.patch = 0
          @version.build_number = 0
          @version = Version.new(@major, @minor, @patch, @build_number)
        else
          super
        end
      end
    end
  end
end
