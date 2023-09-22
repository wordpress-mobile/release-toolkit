module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class IntegerBuildCodeFormatter
        # @param version [AppVersion] An AppVersion object. This parameter is ignored but is included
        # to have a consistent signature with other build code formatters.
        #
        # @param build_code [BuildCode] The BuildCode object to format
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
