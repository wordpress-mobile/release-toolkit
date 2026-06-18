# frozen_string_literal: true

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # Google Play Store's maximum allowed versionCode.
      MAX_PLAY_STORE_VERSION_CODE = 2_100_000_000

      # The `ContinuousBuildCodeFormatter` derives an Android Play Store `versionCode` for a
      # "continuous trunk" release model, where the low-order term is a high-cardinality,
      # monotonically increasing build number (e.g. a Buildkite build number).
      #
      # The build code is computed as:
      #
      #   versionCode = (major * 10 + minor) * 10^build_digits + build_number
      #
      # There is deliberately no patch input: in a continuous-trunk model hotfixes are disambiguated
      # by the (globally monotonic) build number, not by a patch digit.
      #
      # Because the build number is globally monotonic and the version prefix only ever increases,
      # the resulting code is always strictly increasing — even if the build number eventually
      # exceeds `10^build_digits` (which only costs human-readability, not ordering). The only hard
      # correctness constraint is staying at or below the Play Store's max versionCode.
      #
      # Unlike `DerivedBuildCodeFormatter` (fixed-width string concatenation capped at 8 total digits
      # and 3 digits per component, i.e. build <= 999), this formatter can hold a large build number.
      # The two target different release models; this one does not replace the other.
      class ContinuousBuildCodeFormatter
        # @param [Integer] build_digits Number of digits reserved for the build number, which sets the
        # multiplier applied to the `major * 10 + minor` prefix (multiplier = 10^build_digits).
        # Must be a positive integer. Defaults to 6 (multiplier = 1_000_000).
        #
        def initialize(build_digits: 6)
          validate_build_digits!(build_digits)
          @build_digits = build_digits
        end

        # Derive the build code (Android `versionCode`).
        #
        # @param [Integer] major The major (marketing) version number.
        # @param [Integer] minor The minor (marketing) version number. Must be 9 or lower.
        # @param [Integer] build_number A high-cardinality, monotonically increasing build number
        # (e.g. a Buildkite build number).
        #
        # @return [Integer] The derived `versionCode`.
        #
        def build_code(major:, minor:, build_number:)
          # `major * 10 + minor` is only unambiguous while minor is a single digit.
          if minor > 9
            UI.user_error!("Minor version (#{minor}) must be 9 or lower to derive an unambiguous build code with `#{self.class.name}`")
          end

          prefix = (major * 10) + minor
          code = (prefix * (10**@build_digits)) + build_number

          if code > MAX_PLAY_STORE_VERSION_CODE
            UI.user_error!("Derived build code (#{code}) exceeds the maximum allowed Play Store versionCode (#{MAX_PLAY_STORE_VERSION_CODE})")
          end

          code
        end

        private

        # Validates that `build_digits` is a positive integer.
        #
        # @param [Integer] build_digits The build digit count to validate
        #
        # @raise [StandardError] If the value is not a positive integer
        #
        def validate_build_digits!(build_digits)
          unless build_digits.is_a?(Integer)
            UI.user_error!("`build_digits` must be an integer, got: #{build_digits.class}")
          end

          return if build_digits.positive?

          UI.user_error!("`build_digits` must be a positive integer, got: #{build_digits}")
        end
      end
    end
  end
end
