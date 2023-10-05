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

          version.minor == 9 ? next_major_version(version:) : next_minor_version(version:)
        end
      end
    end
  end
end
