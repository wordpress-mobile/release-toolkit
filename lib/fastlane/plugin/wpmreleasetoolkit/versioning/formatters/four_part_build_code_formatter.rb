require_relative '../formatters/four_part_version_formatter'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `FourPartBuildCodeFormatter` is a specialized build code formatter for apps that use
      # build codes in the format of `major.minor.patch.build_number`.
      class FourPartBuildCodeFormatter
        # @param [AppVersion] version The AppVersion object to format
        #
        # @param [BuildCode] build_code A BuildCode object. This parameter is ignored but is included
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
