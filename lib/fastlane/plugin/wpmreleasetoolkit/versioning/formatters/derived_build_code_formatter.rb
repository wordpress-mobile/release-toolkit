# frozen_string_literal: true

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      MAX_TOTAL_DIGITS = 8

      # The `DerivedBuildCodeFormatter` class is a specialized build code formatter for derived build codes.
      # It takes in an AppVersion object and derives a build code from it.
      class DerivedBuildCodeFormatter
        # Initialize the formatter with configurable prefix and digit counts.
        #
        # @param [String] prefix The prefix to use for the build code. Must be a single digit (0-9), or empty string / nil.
        # @param [Integer] major_digits Number of digits for major version. Defaults to 2.
        # @param [Integer] minor_digits Number of digits for minor version. Defaults to 2.
        # @param [Integer] patch_digits Number of digits for patch version. Defaults to 2.
        # @param [Integer] build_digits Number of digits for build number. Defaults to 2.
        #
        def initialize(prefix: nil, major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)
          prefix ||= ''
          validate_prefix!(prefix)
          validate_digit_count!(major_digits)
          validate_digit_count!(minor_digits)
          validate_digit_count!(patch_digits)
          validate_digit_count!(build_digits)
          validate_total_digits!(major_digits, minor_digits, patch_digits, build_digits)

          @prefix = prefix.to_s
          @major_digits = major_digits
          @minor_digits = minor_digits
          @patch_digits = patch_digits
          @build_digits = build_digits
        end

        # Calculate the next derived build code.
        #
        # This method derives a new build code from the given AppVersion object by concatenating the configured prefix,
        # the major version, the minor version, the patch version, and the build number with configurable digit counts.
        #
        # @param [AppVersion] version The AppVersion object to derive the next build code from.
        #
        # @param [BuildCode] build_code A BuildCode object. This parameter is ignored but is included
        # to have a consistent signature with other build code formatters.
        #
        # @return [String] The formatted build code string.
        #
        def build_code(build_code = nil, version:)
          # Validate that version components fit within their configured digit limits
          validate_version_component_fits!(component_value: version.major, digit_limit: @major_digits)
          validate_version_component_fits!(component_value: version.minor, digit_limit: @minor_digits)
          validate_version_component_fits!(component_value: version.patch, digit_limit: @patch_digits)
          validate_version_component_fits!(component_value: version.build_number, digit_limit: @build_digits)

          result = [
            @prefix,
            version.major.to_s.rjust(@major_digits, '0'),
            version.minor.to_s.rjust(@minor_digits, '0'),
            version.patch.to_s.rjust(@patch_digits, '0'),
            version.build_number.to_s.rjust(@build_digits, '0'),
          ].join

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

        # Validates that the digit count is a valid positive integer within reasonable limits.
        #
        # @param [Integer] digit_count The digit count to validate
        #
        # @raise [StandardError] If the digit count is invalid
        #
        def validate_digit_count!(digit_count)
          # Check if it's an integer
          unless digit_count.is_a?(Integer)
            UI.user_error!("Digit count must be an integer, got: #{digit_count.class}")
          end

          return if digit_count.between?(1, 3)

          UI.user_error!("Digit count must be between 1 and 3 digits, got: #{digit_count}")
        end

        # Validates that the total number of digits (excluding prefix) doesn't exceed the maximum for multiplatform compatibility.
        #
        def validate_total_digits!(major_digits, minor_digits, patch_digits, build_digits)
          total_digits = major_digits + minor_digits + patch_digits + build_digits

          # Limit total digits to 8 (excluding prefix)
          return if total_digits <= MAX_TOTAL_DIGITS

          UI.user_error!("Total digit count (#{total_digits}) exceeds maximum allowed (#{MAX_TOTAL_DIGITS}). " \
                         "Current config: major(#{major_digits}) + minor(#{minor_digits}) + patch(#{patch_digits}) + build(#{build_digits}) digits")
        end

        # Validates that a version component value fits within its configured digit limit.
        #
        # @param [Integer] component_value The version component value to validate
        # @param [Integer] digit_limit The maximum number of digits allowed for this component
        #
        # @raise [StandardError] If the component value exceeds the digit limit
        #
        def validate_version_component_fits!(component_value:, digit_limit:)
          # Calculate the maximum value that fits in the digit limit
          max_value = (10**digit_limit) - 1

          return if component_value <= max_value

          UI.user_error!("Version component value (#{component_value}) exceeds maximum allowed " \
                         "for #{digit_limit} digit(s) (max: #{max_value}). Consider increasing the corresponding _digits parameter.")
        end
      end
    end
  end
end
