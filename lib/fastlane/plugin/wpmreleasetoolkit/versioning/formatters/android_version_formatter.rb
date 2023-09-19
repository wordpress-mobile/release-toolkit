# The `AndroidVersionFormatter` class is a specialized version formatter for Android apps,
# extending the `VersionFormatter` class.
require 'fastlane'
require_relative '../../models/app_version'
require_relative 'version_formatter'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class AndroidVersionFormatter < VersionFormatter
        # The string identifier used for beta versions in Android.
        BETA_IDENTIFIER = 'rc'.freeze

        # Get the formatted beta version of the Android app
        #
        # This method constructs a beta version string by combining the release version
        # with the beta identifier and the build number. It ensures that the build number is
        # 1 or higher, as beta versions must have a build number greater than or equal to 1.
        #
        # @return [String] The formatted beta version of the Android app.
        # @raise [UI::Error] If the build number of the beta version is not 1 or higher.
        #
        def beta_version(version)
          # Ensure that the build number is 1 or higher for a beta version
          FastlaneCore::UI.user_error!('The build number of a beta version must be 1 or higher') unless version.build_number.positive?

          # Construct and return the formatted beta version string.
          "#{release_version(version)}-#{BETA_IDENTIFIER}-#{version.build_number}"
        end
      end
    end
  end
end
