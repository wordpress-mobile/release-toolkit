require_relative 'version_calculator_abstract'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `SemanticVersionCalculator` class is a specialized version calculator for semantic versions
      # of an app, extending the `VersionCalculatorAbstract` class.
      class SemanticVersionCalculator < VersionCalculatorAbstract
        # Calculate the next semantic release version.
        #
        # @param [AppVersion] version The version to calculate the next semantic release version from.
        #
        # @return [AppVersion] The next semantic release version.
        #
        def next_release_version(version:)
          next_minor_version(version: version)
        end

        # Calculate the previous semantic release version.
        #
        # @param [AppVersion] version The version to calculate the previous semantic release version for.
        #
        # @return [AppVersion] The previous semantic release version.
        #
        def previous_release_version(version:)
          previous_minor_version(version: version)
        end
      end
    end
  end
end
