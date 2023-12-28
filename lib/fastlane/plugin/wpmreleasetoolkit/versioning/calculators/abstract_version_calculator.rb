module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `AbstractVersionCalculator` class is responsible for performing version calculations and transformations. It can be used
      # as a base class for version calculations that use different versioning schemes. It contains calculation and
      # transformation methods that are shared by all platforms. It has the abstract suffix because it should not be
      # instantiated directly.
      class AbstractVersionCalculator
        # This method increments the major version component and resets minor, patch, and build number
        # components to zero.
        #
        # @param version [AppVersion] The version to calculate the next major version for.
        #
        # @return [AppVersion] The next major version.
        #
        def next_major_version(version:)
          new_version = version.dup
          new_version.major += 1
          new_version.minor = 0
          new_version.patch = 0
          new_version.build_number = 0

          new_version
        end

        # This method increments the minor version component and resets patch and build number components
        # to zero.
        #
        # @param version [AppVersion] The version to calculate the next minor version for.
        #
        # @return [AppVersion] The next minor version.
        #
        def next_minor_version(version:)
          new_version = version.dup
          new_version.minor += 1
          new_version.patch = 0
          new_version.build_number = 0

          new_version
        end

        # This method increments the patch version component and resets the build number component to zero.
        #
        # @param version [AppVersion] The version to calculate the next patch version for.
        #
        # @return [AppVersion] The next patch version.
        #
        def next_patch_version(version:)
          new_version = version.dup
          new_version.patch += 1
          new_version.build_number = 0

          new_version
        end

        # This method increments the build number component.
        #
        # @param version [AppVersion] The version to calculate the next build number for.
        #
        # @return [AppVersion] The next version with an incremented build number.
        #
        def next_build_number(version:)
          new_version = version.dup
          new_version.build_number += 1

          new_version
        end

        # Calculate the previous patch version by decrementing the patch version if it's not zero.
        #
        # @param [AppVersion] version The version to calculate the previous patch version for.
        #
        # @return [AppVersion] The previous patch version.
        #
        def previous_patch_version(version:)
          new_version = version.dup
          new_version.patch -= 1 unless version.patch.zero?
          new_version.build_number = 0

          new_version
        end

        # Calculate whether a release is a hotfix release.
        #
        # @param [AppVersion] version The version to check.
        #
        # @return [Boolean] Whether the release is a hotfix release.
        #
        def release_is_hotfix(version:)
          version.patch.positive?
        end
      end
    end
  end
end
