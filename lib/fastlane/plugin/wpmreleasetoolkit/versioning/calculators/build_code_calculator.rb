# The `BuildCodeCalculator` class is responsible for performing calculations on build codes.

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class BuildCodeCalculator
        # Calculate the next simple build code.
        #
        # This method increments the build code value by 1.
        #
        # @param after [BuildCode] The build code to increment.
        #
        # @return [BuildCode] The next build code.
        #
        def next_simple_build_code(after:)
          after + 1
        end

        # Calculate the next derived build code.
        #
        # This method derives a new build code from the given AppVersion object. The derived build code
        # is a concatenation of the digit 1, the major version, the minor version, the patch version, and
        # the build number. The derived build code is then incremented by 1.
        #
        # @param after [AppVersion] The version to derive the next build code from.
        #
        # @return [BuildCode] The next derived build code.
        #
        def next_derived_build_code(after:)
          after.build_number += 1

          derived_build_code = Fastlane::Models::BuildCode.new(
            format(
              '1%02d%02d%02d%02d',
              after.major,
              after.minor,
              after.patch,
              after.build_number
            ).to_i
          )

          derived_build_code
        end
      end
    end
  end
end
