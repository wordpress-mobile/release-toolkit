require_relative 'abstract_version_formatter'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `FourPartVersionFormatter` class  extends the `VersionFormatter` class. It is a specialized version formatter for
      # apps that use versions in the format of `1.2.3.4`.
      class FourPartVersionFormatter < AbstractVersionFormatter
        # Parse the version string into an AppVersion instance
        #
        # @param [String] version The version string to parse
        #
        # @return [AppVersion] The parsed version
        #
        def parse(version)
          # Split the version string into its components
          components = version.split('.').map(&:to_i)

          # Create a new AppVersion instance from the version string components
          Fastlane::Models::AppVersion.new(*components)
        end

        # Return the formatted version string
        #
        # @param [AppVersion] version The version object to format
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
