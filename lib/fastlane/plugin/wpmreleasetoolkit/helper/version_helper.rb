module Fastlane
  module Helper
    # Helper methods with shared logic between Android/iOS/macOS to execute version-related operations
    module VersionHelper

      # The index for the major version number part
      MAJOR_NUMBER = 0
      # The index for the minor version number part
      MINOR_NUMBER = 1

      def self.increment_version_using_calendar_versioning(version_parts)
        # We only want to bump the major version if the code freeze is for the first version of the next year
        if Time.now.month == 12 && UI.confirm('Is this release the first release of next year?')
          version_parts[MAJOR_NUMBER] += 1
          version_parts[MINOR_NUMBER] = 1
        end

        "#{version_parts[MAJOR_NUMBER]}.#{version_parts[MINOR_NUMBER]}"
      end

      def self.increment_version_using_marketing_versioning(version_parts)
        if version_parts[MINOR_NUMBER] == 10
          version_parts[MAJOR_NUMBER] += 1
          version_parts[MINOR_NUMBER] = 0
        end

        "#{version_parts[MAJOR_NUMBER]}.#{version_parts[MINOR_NUMBER]}"
      end
    end
  end
end
