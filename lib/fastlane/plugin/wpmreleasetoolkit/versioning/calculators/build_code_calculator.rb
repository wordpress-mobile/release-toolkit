# The `BuildCodeCalculator` class is responsible for performing calculations on build codes.

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class BuildCodeCalculator
        # Calculate the next build code.
        #
        # This method increments the build code value by 1.
        #
        # @return [BuildCode] The next build code.
        #
        def next_build_code(after:)
          after + 1
        end
      end
    end
  end
end
