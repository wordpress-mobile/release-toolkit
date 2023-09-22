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
        def next_build_code(after:)
          after.build_code + 1

          after
        end

        # Calculate the next derived build code.
        #
        # This method derives a new build code from the given AppVersion object by concatenating the digit 1,
        # the major version, the minor version, the patch version, and the build number.
        #
        # @param after [AppVersion] The version to derive the next build code from.
        #
        # @return [BuildCode] The next derived build code.
        #
        def next_derived_build_code(after:)
          Fastlane::Models::BuildCode.new(
            format(
              # 1 is appended to the beginning of the string in case there needs to be additional platforms or
              # extensions that could then use a different digit prefix such as 2, etc.
              '1%<major>.2i%<minor>.2i%<patch>.2i%<build_number>.2i',
              major: after.major,
              minor: after.minor,
              patch: after.patch,
              build_number: after.build_number
            ).to_i
          )
        end
      end
    end
  end
end
