module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `SimpleBuildCodeCalculator` class is a build code calculator for apps that use simple integer
      # build codes.
      class SimpleBuildCodeCalculator
        # Calculate the next build code.
        #
        # This method increments the build code value by 1.
        #
        # @param [BuildCode] version The build code to increment.
        #
        # @return [BuildCode] The next build code.
        #
        def next_build_code(build_code:)
          new_build_code = build_code.dup
          new_build_code.build_code += 1
        end
      end
    end
  end
end
