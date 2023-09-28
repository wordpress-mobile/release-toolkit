require_relative 'abstract_version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `MarketingVersionCalculator` class is a specialized version calculator for marketing versions
      # of an app, extending the `AbstractVersionCalculator` class.
      class MarketingVersionCalculator < AbstractVersionCalculator
        # Calculate the next marketing release version.
        #
        # This method checks if the minor version is 9. If it is, it calculates the next major version.
        # Otherwise, it calculates the next minor version. The patch and build number components are reset to zero.
        #
        # @param [AppVersion] version The version to calculate the next marketing release version for.
        #
        # @return [AppVersion] The next marketing release version.
        #
        def next_release_version(version:)
          UI.user_error!('Marketing Versioning: The minor version cannot be greater than 9') if version.minor > 9

          version.minor == 9 ? next_major_version(version: version) : next_minor_version(version: version)
        end

        # Calculate the previous marketing release version.
        #
        # If the minor version is zero, it calculates the previous major version and sets the minor
        # version to 9. Otherwise, it calculates the previous minor version. The patch and build number
        # components are reset to zero.
        #
        # @param [AppVersion] version The version to calculate the previous marketing release version for.
        #
        # @return [AppVersion] The previous marketing release version.
        #
        def previous_release_version(version:)
          new_version = version.dup
          if version.minor.zero?
            new_version.major -= 1
            new_version.minor = 9
            new_version.patch = 0
            new_version.build_number = 0

            new_version
          else
            previous_minor_version(version: version)
          end
        end
      end
    end
  end
end
