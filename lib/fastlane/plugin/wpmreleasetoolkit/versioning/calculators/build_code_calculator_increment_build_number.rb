module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class IncrementBuildNumberBuildCodeCalculator
        # Calculate the next build code.
        #
        # This method increments the build code value by 1.
        #
        # @param after [AppVersion] The AppVersion with the build number to increment.
        #
        # @return [BuildCode] The next build code.
        #
        def next_build_code(after:)
          after.build_number += 1

          Fastlane::Models::BuildCode.new(after.build_number)
        end
      end
    end
  end
end
