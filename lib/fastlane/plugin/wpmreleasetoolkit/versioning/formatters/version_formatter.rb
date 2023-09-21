# The `VersionFormatter` class is a generic version formatter that can be used as a base class
# for formatting version objects used by for different platforms. It contains formatting methods that
# are shared by all platforms.
require_relative '../calculators/version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class VersionFormatter
        # Get the release version string for the app.
        #
        # This method constructs the release version string based on the major, minor, and
        # patch components of the provided `@version`. If the patch component is zero, it returns
        # a version string in the format "major.minor" (e.g., '1.2'). Otherwise, it returns a
        # version string in the format "major.minor.patch" (e.g., '1.2.3').
        #
        # @param version [AppVersion] The version object to format
        #
        # @return [String] The formatted release version string.
        #
        def release_version(version)
          version.patch.zero? ? "#{version.major}.#{version.minor}" : "#{version.major}.#{version.minor}.#{version.patch}"
        end
      end
    end
  end
end
