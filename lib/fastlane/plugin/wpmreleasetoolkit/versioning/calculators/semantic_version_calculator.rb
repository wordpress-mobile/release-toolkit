require_relative 'abstract_version_calculator'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `SemanticVersionCalculator` class is a specialized version calculator for semantic versions
      # of an app, extending the `AbstractVersionCalculator` class.
      class SemanticVersionCalculator < AbstractVersionCalculator
        # Calculate the next semantic release version.
        #
        # @param [AppVersion] version The version to calculate the next semantic release version from.
        #
        # @return [AppVersion] The next semantic release version.
        #
        def next_release_version(version:)
          next_minor_version(version: version)
        end
      end
    end
  end
end
