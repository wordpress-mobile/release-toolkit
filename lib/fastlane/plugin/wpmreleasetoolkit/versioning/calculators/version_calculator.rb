# The `VersionCalculator` class is responsible for performing version calculations and transformations. It can be used
# as a base class for version calculations that use different versioning schemes. It contains calculation and
# transformation methods that are shared by all platforms.
require_relative '../../models/app_version'

module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class VersionCalculator
        # This method increments the major version component and resets minor, patch, and build number
        # components to zero.
        #
        # @return [AppVersion] The next major version.
        #
        def calculate_next_major_version(version)
          version.major += 1
          version.minor = 0
          version.patch = 0
          version.build_number = 0

          version
        end

        # This method increments the minor version component and resets patch and build number components
        # to zero.
        #
        # @return [AppVersion] The next minor version.
        #
        def calculate_next_minor_version(version)
          version.minor += 1
          version.patch = 0
          version.build_number = 0

          version
        end

        # This method increments the patch version component and resets the build number component to zero.
        #
        # @return [AppVersion] The next patch version.
        #
        def calculate_next_patch_version(version)
          version.patch += 1
          version.build_number = 0

          version
        end

        # This method increments the build number component.
        #
        # @return [AppVersion] The next version with an incremented build number.
        #
        def calculate_next_build_number(version)
          version.build_number += 1

          version
        end

        # Get the current date in the format 'YYYYMMDD'.
        #
        # @return [String] The current date in 'YYYYMMDD' format.
        #
        def today_date
          DateTime.now.strftime('%Y%m%d')
        end

        # Calculate the next internal version by setting the build number to the current date.
        #
        # @return [AppVersion] The next version with the build number set to the current date.
        #
        def calculate_next_internal_version(version)
          version.build_number = today_date

          version
        end

        # Check if this version number represents a patch version.
        #
        # @return [Boolean] `true` if it's a patch version, `false` otherwise.
        #
        def patch?(version)
          !version.patch.zero?
        end

        # Calculate the previous minor version by decrementing the minor version.
        #
        # @return [AppVersion] The previous minor version.
        #
        def calculate_previous_minor_version(version)
          version.minor -= 1
          version.patch = 0
          version.build_number = 0

          version
        end

        # Calculate the previous patch version by decrementing the patch version if it's not zero.
        #
        # @return [AppVersion] The previous patch version.
        #
        def calculate_previous_patch_version(version)
          version.patch -= 1 unless version.patch.zero?
          version.build_number = 0

          version
        end

        # Calculate the previous build number by decrementing the build number.
        #
        # @return [AppVersion] The previous version with a decremented build number.
        #
        def calculate_previous_build_number(version)
          version.build_number -= 1

          version
        end
      end
    end
  end
end
