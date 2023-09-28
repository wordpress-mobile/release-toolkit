# The `SemanticVersionCalculator` class is a specialized version calculator for semantic versions
# of an app, extending the `VersionCalculatorAbstract` class.
require_relative 'version_calculator_abstract'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class SemanticVersionCalculator < VersionCalculatorAbstract
        # Calculate the next semantic release version.
        #
        def next_release_version(version:)
          next_minor_version(version: version)
        end

        # Calculate the previous semantic release version.
        #
        def previous_release_version(version:)
          previous_minor_version(version: version)
        end
      end
    end
  end
end
