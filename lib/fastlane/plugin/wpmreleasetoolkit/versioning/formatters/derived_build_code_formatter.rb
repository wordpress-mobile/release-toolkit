# frozen_string_literal: true

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `DerivedBuildCodeFormatter` class is a specialized build code formatter for derived build codes.
      # It takes in an AppVersion object and derives a build code from it.
      class DerivedBuildCodeFormatter
        # Initialize the formatter with a configurable prefix.
        #
        # @param [String] prefix The prefix to use for the build code. Must be a single digit (0-9). Defaults to '1' for backward compatibility.
        #
        def initialize(prefix: '1')
          validate_prefix!(prefix)
          @prefix = prefix.to_s
        end

        # Calculate the next derived build code.
        #
        # This method derives a new build code from the given AppVersion object by concatenating the configured prefix,
        # the major version, the minor version, the patch version, and the build number.
        #
        # @param [AppVersion] version The AppVersion object to derive the next build code from.
        #
        # @param [BuildCode] build_code A BuildCode object. This parameter is ignored but is included
        # to have a consistent signature with other build code formatters.
        #
        # @return [String] The formatted build code string.
        #
        def build_code(build_code = nil, version:)
          result = format(
            # The prefix is configurable to allow for additional platforms or
            # extensions that could use a different digit prefix such as 2, etc.
            '%<prefix>s%<major>.2i%<minor>.2i%<patch>.2i%<build_number>.2i',
            prefix: @prefix,
            major: version.major,
            minor: version.minor,
            patch: version.patch,
            build_number: version.build_number
          )

          result.gsub(/^0+/, '')
        end

        private

        # Validates that the prefix is a valid single digit (0-9) or empty string.
        #
        # @param [String] prefix The prefix to validate
        #
        # @raise [StandardError] If the prefix is invalid
        #
        def validate_prefix!(prefix)
          prefix_str = prefix.to_s

          # Allow empty string
          return if prefix_str.empty?

          # Check if it's longer than 1 character
          if prefix_str.length > 1
            UI.user_error!("Prefix must be a single digit or empty string, got: '#{prefix_str}' (length: #{prefix_str.length})")
          end

          # Check if it's a valid integer
          return if ('0'..'9').include?(prefix_str)

          UI.user_error!("Prefix must be an integer digit (0-9) or empty string, got: '#{prefix_str}'")
        end
      end
    end
  end
end
