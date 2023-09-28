# The `FourPartVersionFormatter` class  extends the `VersionFormatter` class. It is a specialized version formatter for
# apps that use versions in the format of `1.2.3.4`.
require_relative 'version_formatter_abstract'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class FourPartVersionFormatter < VersionFormatterAbstract
        # Parse the version string into an AppVersion instance
        #
        # @param version [String] The version string to parse
        #
        # @return [AppVersion] The parsed version
        #
        def parse(version)
          # Split the version string into its components
          components = version.split('.')

          # Create a new AppVersion instance from the version string components
          Fastlane::Models::AppVersion.new(*components.map(&:to_i))
        end

        # Return the formatted version string
        #
        # @param version [AppVersion] The version object to format
        #
        # @return [String] The formatted version string
        #
        def to_s(version)
          "#{version.major}.#{version.minor}.#{version.patch}.#{version.build_number}"
        end
      end
    end
  end
end
