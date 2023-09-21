# The `VersionCalculator` class is responsible for performing version calculations and transformations. It can be used
# as a base class for version calculations that use different versioning schemes. It contains calculation and
# transformation methods that are shared by all platforms.

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class VersionCalculator
        # This method increments the major version component and resets minor, patch, and build number
        # components to zero.
        #
        # @param after [AppVersion] The version to calculate the next major version for.
        #
        # @return [AppVersion] The next major version.
        #
        def next_major_version(after:)
          after.major += 1
          after.minor = 0
          after.patch = 0
          after.build_number = 0

          after
        end

        # This method increments the minor version component and resets patch and build number components
        # to zero.
        #
        # @param after [AppVersion] The version to calculate the next minor version for.
        #
        # @return [AppVersion] The next minor version.
        #
        def next_minor_version(after:)
          after.minor += 1
          after.patch = 0
          after.build_number = 0

          after
        end

        # This method increments the patch version component and resets the build number component to zero.
        #
        # @param after [AppVersion] The version to calculate the next patch version for.
        #
        # @return [AppVersion] The next patch version.
        #
        def next_patch_version(after:)
          after.patch += 1
          after.build_number = 0

          after
        end

        # This method increments the build number component.
        #
        # @param after [AppVersion] The version to calculate the next build number for.
        #
        # @return [AppVersion] The next version with an incremented build number.
        #
        def next_build_number(after:)
          after.build_number += 1

          after
        end

        # Calculate the next internal version by setting the build number to the current date.
        #
        # @return [AppVersion] The next version with the build number set to the current date.
        #
        def next_internal_version(after:)
          after.build_number = today_date

          after
        end

        # Check if this version number represents a patch version.
        #
        # @return [Boolean] `true` if it's a patch version, `false` otherwise.
        #
        def patch?(version)
          !version.patch.zero?
        end

        # Calculate the previous major version by decrementing the minor version.
        #
        # @param before [AppVersion] The version to calculate the previous major version for.
        #
        # @return [AppVersion] The previous major version.
        #
        def previous_major_version(before:)
          before.major -= 1
          before.minor = 0
          before.patch = 0
          before.build_number = 0

          before
        end

        # Calculate the previous minor version by decrementing the minor version.
        #
        # @param before [AppVersion] The version to calculate the previous minor version for.
        #
        # @return [AppVersion] The previous minor version.
        #
        def previous_minor_version(before:)
          before.minor -= 1
          before.patch = 0
          before.build_number = 0

          before
        end

        # Calculate the previous patch version by decrementing the patch version if it's not zero.
        #
        # @param before [AppVersion] The version to calculate the previous patch version for.
        #
        # @return [AppVersion] The previous patch version.
        #
        def previous_patch_version(before:)
          before.patch -= 1 unless before.patch.zero?
          before.build_number = 0

          before
        end

        # Calculate the previous build number by decrementing the build number.
        #
        # @param before [AppVersion] The version to calculate the previous build number for.
        #
        # @return [AppVersion] The previous version with a decremented build number.
        #
        def previous_build_number(before:)
          before.build_number -= 1

          before
        end

        private

        # Get the current date in the format 'YYYYMMDD'.
        #
        # @return [String] The current date in 'YYYYMMDD' format.
        #
        def today_date
          DateTime.now.strftime('%Y%m%d')
        end
      end
    end
  end
end
