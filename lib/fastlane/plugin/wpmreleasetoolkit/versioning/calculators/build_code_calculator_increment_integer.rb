module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class SimpleBuildCodeCalculator
        # Calculate the next build code.
        #
        # This method increments the build code value by 1.
        #
        # @param after [BuildCode] The build code to increment.
        #
        # @return [BuildCode] The next build code.
        #
        def next_build_code(after:)
          after.build_code += 1
        end
      end
    end
  end
end
