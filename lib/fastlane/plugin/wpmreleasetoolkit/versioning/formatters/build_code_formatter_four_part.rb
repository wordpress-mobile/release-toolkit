require_relative '../formatters/version_formatter_four_part'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class FourPartBuildCodeFormatter
        # @param version [AppVersion] The AppVersion object to format
        #
        # @param build_code [BuildCode] A BuildCode object. This parameter is ignored but is included
        # to have a consistent signature with other build code formatters.
        #
        # @return [String] The formatted build code string.
        #
        def build_code(build_code = nil, version:)
          FourPartVersionFormatter.new.to_s(version)
        end
      end
    end
  end
end
