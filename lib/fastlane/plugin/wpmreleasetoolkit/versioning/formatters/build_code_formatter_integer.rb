module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `IntegerBuildCodeFormatter` is a specialized build code formatter for apps that use simple
      # integer build codes in the format of `build_number`.
      class IntegerBuildCodeFormatter
        # @param version [AppVersion] An AppVersion object. This parameter is ignored but is included
        # to have a consistent signature with other build code formatters.
        #
        # @param [BuildCode] build_code The BuildCode object to format
        #
        # @return [String] The formatted build code string.
        #
        def build_code(version = nil, build_code:)
          build_code.to_s
        end
      end
    end
  end
end
