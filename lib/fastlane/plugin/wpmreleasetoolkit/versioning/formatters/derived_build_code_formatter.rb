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
        # @param [Integer] major_digits Number of digits for major version. Must be between 1–3. Defaults to 2.
        # @param [Integer] minor_digits Number of digits for minor version. Must be between 1–3. Defaults to 2.
        # @param [Integer] patch_digits Number of digits for patch version. Must be between 1–3. Defaults to 2.
        # @param [Integer] build_digits Number of digits for build number. Must be between 1–3. Defaults to 2.
        #
        def initialize(prefix: nil, major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)
          prefix ||= ''
          validate_prefix!(prefix)
          @prefix = prefix.to_s

          @digit_counts = [major_digits, minor_digits, patch_digits, build_digits]
          @digit_counts.each { |d| validate_digit_count!(d) }
          validate_total_digits!(@digit_counts)
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
        def build_code(_build_code = nil, version:)
          formatted_components = version.components.zip(@digit_counts).map do |value, width|
            comp = value.to_s.rjust(width, '0')
            if comp.length > width
              UI.user_error!("Version component value (#{value}) exceeds maximum allowed width of #{width} characters. " \
                             "Consider increasing the corresponding `*_digits` parameter of your `#{self.class.name}`")
            end
            comp
          end
          [@prefix, *formatted_components].join.gsub(/^0+/, '')
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
        def validate_total_digits!(digits_list)
          total_digits = digits_list.sum

          # Limit total digits to 8 (excluding prefix)
          return if total_digits <= MAX_TOTAL_DIGITS

          UI.user_error!("Total digit count (#{total_digits}) exceeds maximum allowed (#{MAX_TOTAL_DIGITS}). " \
                         "Current config: major(#{digits_list[0]}) + minor(#{digits_list[1]}) + patch(#{digits_list[2]}) + build(#{digits_list[3]}) digits")
        end
      end
    end
  end
end
