require 'xcodeproj'

module Fastlane
  module Helper
    module Ios
      # A module containing helper methods to manipulate/extract/bump iOS version strings in xcconfig files
      #
      module VersionHelper
        # The index for the major version number part
        MAJOR_NUMBER = 0
        # The index for the minor version number part
        MINOR_NUMBER = 1
        # The index for the hotfix version number part
        HOTFIX_NUMBER = 2
        # The index for the build version number part
        BUILD_NUMBER = 3

        # Compute the name of the next release version.
        #
        # @param [String] version The current version that we want to increment
        #
        # @return [String] The predicted next version, in the form of "X.Y".
        #         Corresponds to incrementing the minor part, except if it reached 10
        #         (in that case we go to the next major version, as decided in our versioning conventions)
        #
        def self.calc_next_release_version(version)
          vp = get_version_parts(version)
          vp[MINOR_NUMBER] += 1
          if vp[MINOR_NUMBER] == 10
            vp[MAJOR_NUMBER] += 1
            vp[MINOR_NUMBER] = 0
          end

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        #----------------------------------------

        # Split a version string into its 4 parts, ensuring its parts count is valid
        #
        # @param [String] version The version string to split into parts
        # @return [Array<String>] An array of exactly 4 elements, containing each part of the version string.
        # @note If the original version string contains less than 4 parts, the returned array is filled with zeros at the end to always contain 4 items.
        # @raise [UserError] Interrupts the lane if the provided version contains _more_ than 4 parts
        #
        def self.get_version_parts(version)
          parts = version.split('.')
          parts = parts.fill('0', parts.length...4).map(&:to_i)
          UI.user_error!("Bad version string: #{version}") if parts.length > 4

          parts
        end

        # Check if a string is an integer
        #
        # @param [String] string The string to test
        #
        # @return [Bool] true if the string is representing an integer value, false if not
        #
        def self.is_int?(string)
          true if Integer(string)
        rescue StandardError
          false
        end
      end
    end
  end
end
