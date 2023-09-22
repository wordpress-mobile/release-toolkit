module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class DerivedOptionTwoBuildCodeFormatter
        # Calculate the next derived build code.
        #
        # This method derives a new build code from the given AppVersion object by concatenating
        # the major version, the minor version, the patch version, and the build number.
        #
        # @param version [AppVersion] The AppVersion object to derive the next build code from.
        #
        # @param build_code [BuildCode] A BuildCode object. This parameter is ignored but is included
        # to have a consistent signature with other build code formatters.
        #
        # @return [String] The formatted build code string.
        #
        def build_code(build_code = nil, version:)
          format(
            # 1 is appended to the beginning of the string in case there needs to be additional platforms or
            # extensions that could then use a different digit prefix such as 2, etc.
            '%<major>i%<minor>.1i%<patch>.1i%<build_number>.2i',
            major: version.major,
            minor: version.minor,
            patch: version.patch,
            build_number: version.build_number
          )
        end
      end
    end
  end
end
