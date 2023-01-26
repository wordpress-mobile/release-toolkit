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

        # Returns the public-facing version string.
        #
        # @param [String] xcconfig_file The path for the .xcconfig file containing the public-facing version
        #
        # @return [String] The public-facing version number, extracted from the VERSION_LONG entry of the xcconfig file.
        #         - If this version is a hotfix (more than 2 parts and 3rd part is non-zero), returns the "X.Y.Z" formatted string
        #         - Otherwise (not a hotfix / 3rd part of version is 0), returns "X.Y" formatted version number
        #
        def self.get_xcconfig_public_version(xcconfig_file:)
          version = read_long_version_from_config_file(xcconfig_file)
          vp = get_version_parts(version)
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}" unless is_hotfix?(version)

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end

        # Returns the public-facing version string.
        #
        # @return [String] The public-facing version number, extracted from the VERSION_LONG entry of the xcconfig file.
        #         - If this version is a hotfix (more than 2 parts and 3rd part is non-zero), returns the "X.Y.Z" formatted string
        #         - Otherwise (not a hotfix / 3rd part of version is 0), returns "X.Y" formatted version number
        #
        # @deprecated This method is going to be removed soon due to it's dependency on `ENV['PUBLIC_CONFIG_FILE']` via `get_build_version`.
        #
        def self.get_public_version
          version = get_build_version()
          vp = get_version_parts(version)
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}" unless is_hotfix?(version)

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end

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

        # Return the short version string "X.Y" from the full version.
        #
        # @param [String] version The version to convert to a short version
        #
        # @return [String] A version string consisting of only the first 2 parts "X.Y"
        #
        def self.get_short_version_string(version)
          vp = get_version_parts(version)
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        # Compute the name of the previous release version.
        #
        # @param [String] version The current version we want to decrement
        #
        # @return [String] The predicted previous version, in the form of "X.Y".
        #         Corresponds to decrementing the minor part, or decrement the major and set minor to 9 if minor was 0.
        #
        def self.calc_prev_release_version(version)
          vp = get_version_parts(version)
          if vp[MINOR_NUMBER] == 0
            vp[MAJOR_NUMBER] -= 1
            vp[MINOR_NUMBER] = 9
          else
            vp[MINOR_NUMBER] -= 1
          end

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        # Compute the name of the next build version.
        #
        # @param [String] version The current version we want to increment
        #
        # @return [String] The predicted next build version, in the form of "X.Y.Z.N".
        #         Corresponds to incrementing the last (4th) component N of the version.
        #
        def self.calc_next_build_version(version)
          vp = get_version_parts(version)
          vp[BUILD_NUMBER] += 1
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{vp[BUILD_NUMBER]}"
        end

        # Compute the name of the next hotfix version.
        #
        # @param [String] version The current version we want to increment
        #
        # @return [String] The predicted next hotfix version, in the form of "X.Y.Z".
        #         Corresponds to incrementing the 3rd component of the version.
        #
        def self.calc_next_hotfix_version(version)
          vp = get_version_parts(version)
          vp[HOTFIX_NUMBER] += 1
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end

        # Compute the name of the previous build version.
        #
        # @param [String] version The current version we want to decrement
        #
        # @return [String] The predicted previous build version, in the form of "X.Y.Z.N".
        #         Corresponds to decrementing the last (4th) component N of the version.
        #
        def self.calc_prev_build_version(version)
          vp = get_version_parts(version)
          vp[BUILD_NUMBER] -= 1 unless vp[BUILD_NUMBER] == 0
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{vp[BUILD_NUMBER]}"
        end

        # Compute the name of the previous hotfix version.
        #
        # @param [String] version The current version we want to decrement
        #
        # @return [String] The predicted previous hotfix version, in the form of "X.Y.Z", or "X.Y" if Z is 0.
        #         Corresponds to decrementing the 3rd component Z of the version, striping it if it ends up being zero.
        #
        def self.calc_prev_hotfix_version(version)
          vp = get_version_parts(version)
          vp[HOTFIX_NUMBER] -= 1 unless vp[HOTFIX_NUMBER] == 0
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}" unless vp[HOTFIX_NUMBER] == 0

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        # Create an internal version number, for which the build number is based on today's date.
        #
        # @param [String] version The current version to create an internal version name for.
        #
        # @return [String] The internal version, in the form of "X.Y.Z.YYYYMMDD".
        #
        def self.create_internal_version(version)
          vp = get_version_parts(version)
          d = DateTime.now
          today_date = d.strftime('%Y%m%d')
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{today_date}"
        end

        # Return the build number value incremented by one.
        #
        # @param [String|Int|nil] build_number The build number to increment
        #
        # @return [Int] The incremented build number, or 0 if it was `nil`.
        #
        def self.bump_build_number(build_number)
          build_number.nil? ? 0 : build_number.to_i + 1
        end

        # Determines if a version number corresponds to a hotfix
        #
        # @param [String] version The version number to test
        #
        # @return [Bool] True if the version number has a non-zero 3rd component, meaning that it is a hotfix version.
        #
        def self.is_hotfix?(version)
          vp = get_version_parts(version)
          return (vp.length > 2) && (vp[HOTFIX_NUMBER] != 0)
        end

        # Returns the current value of the `VERSION_LONG` key from the public xcconfig file
        #
        # @return [String] The current version according to the public xcconfig file.
        #
        def self.get_build_version
          xcconfig_file = ENV['PUBLIC_CONFIG_FILE']
          read_long_version_from_config_file(xcconfig_file)
        end

        # Returns the current value of the `VERSION_LONG` key from the internal xcconfig file
        #
        # @return [String] The current version according to the internal xcconfig file.
        #
        def self.get_internal_version
          xcconfig_file = ENV['INTERNAL_CONFIG_FILE']
          read_long_version_from_config_file(xcconfig_file)
        end

        # Prints the current and next release version numbers to stdout, then return the next release version
        #
        # @return [String] The next release version to use after bumping the currently used public version.
        #
        def self.bump_version_release
          # Bump release
          current_version = get_public_version
          UI.message("Current version: #{current_version}")
          new_version = calc_next_release_version(current_version)
          UI.message("New version: #{new_version}")
          verified_version = verify_version(new_version)

          return verified_version
        end

        # Updates the `app_version` entry in the `Deliverfile`
        #
        # @param [String] new_version The new value to set the `app_version` entry to.
        # @raise [UserError] If the Deliverfile was not found.
        #
        def self.update_fastlane_deliver(new_version)
          fd_file = './fastlane/Deliverfile'
          if File.exist?(fd_file)
            Action.sh("sed -i '' \"s/app_version.*/app_version \\\"#{new_version}\\\"/\" #{fd_file}")
          else
            UI.user_error!("Can't find #{fd_file}.")
          end
        end

        # Update the `.xcconfig` files (the public one, and the internal one if it exists) with the new version strings.
        #
        # @env PUBLIC_CONFIG_FILE The path to the xcconfig file containing the public version numbers.
        # @env INTERNAL_CONFIG_FILE The path to the xcconfig file containing the internal version numbers. Can be nil.
        #
        # @param [String] new_version The new version number to use as `VERSION_LONG` for the public xcconfig file
        # @param [String] new_version_short The new version number to use for `VERSION_SHORT` (for both public and internal xcconfig files)
        # @param [String] internal_version The new version number to use as `VERSION_LONG` for the interrnal xcconfig file, if it exists
        #
        def self.update_xc_configs(new_version, new_version_short, internal_version)
          update_xc_config(ENV['PUBLIC_CONFIG_FILE'], new_version, new_version_short)
          update_xc_config(ENV['INTERNAL_CONFIG_FILE'], internal_version, new_version_short) unless ENV['INTERNAL_CONFIG_FILE'].nil?
        end

        # Updates an xcconfig file with new values for VERSION_SHORT and VERSION_LONG entries.
        # Also bumps the BUILD_NUMBER value from that config file if there is one present.
        #
        # @param [String] file_path The path to the xcconfig file
        # @param [String] new_version The new version number to use for VERSION_LONG
        # @param [String] new_version_short The new version number to use for VERSION_SHORT
        # @raise [UserError] If the xcconfig file was not found
        #
        def self.update_xc_config(file_path, new_version, new_version_short)
          if File.exist?(file_path)
            UI.message("Updating #{file_path} to version #{new_version_short}/#{new_version}")
            Action.sh("sed -i '' \"$(awk '/^VERSION_SHORT/{ print NR; exit }' \"#{file_path}\")s/=.*/=#{new_version_short}/\" \"#{file_path}\"")
            Action.sh("sed -i '' \"$(awk '/^VERSION_LONG/{ print NR; exit }' \"#{file_path}\")s/=.*/=#{new_version}/\" \"#{file_path}\"")

            build_number = read_build_number_from_config_file(file_path)
            unless build_number.nil?
              new_build_number = bump_build_number(build_number)
              Action.sh("sed -i '' \"$(awk '/^BUILD_NUMBER/{ print NR; exit }' \"#{file_path}\")s/=.*/=#{new_build_number}/\" \"#{file_path}\"")
            end
          else
            UI.user_error!("#{file_path} not found")
          end
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
          parts = parts.fill('0', parts.length...4).map { |chr| chr.to_i }
          UI.user_error!("Bad version string: #{version}") if parts.length > 4

          return parts
        end

        # Extract the VERSION_LONG entry from an `xcconfig` file
        #
        # @param [String] file_path The path to the `.xcconfig` file to read the value from
        # @return [String] The long version found in said xcconfig file, or nil if not found
        #
        def self.read_long_version_from_config_file(file_path)
          read_from_config_file('VERSION_LONG', file_path)
        end

        # Extract the BUILD_NUMBER entry from an `xcconfig` file
        #
        # @param [String] file_path The path to the `.xcconfig` file to read the value from
        # @return [String] The build number found in said xcconfig file, or nil if not found
        #
        def self.read_build_number_from_config_file(file_path)
          read_from_config_file('BUILD_NUMBER', file_path)
        end

        # Read the value of a given key from an `.xcconfig` file.
        #
        # @param [String] key The xcconfig key to get the value for
        # @param [String] file_path The path to the `.xcconfig` file to read the value from
        #
        # @return [String] The value for the given key, or `nil` if the key was not found.
        #
        def self.read_from_config_file(key, file_path)
          File.open(file_path, 'r') do |f|
            f.each_line do |line|
              line = line.strip
              return line.split('=')[1] if line.start_with?("#{key}=")
            end
          end

          return nil
        end

        # Ensure that the version provided is only composed of number parts and return the validated string
        #
        # @param [String] version The version string to validate
        # @return [String] The version string, re-validated as being a string of the form `X.Y.Z.T`
        # @raise [UserError] Interrupts the lane with a user_error! if the version contains non-numberic parts
        #
        def self.verify_version(version)
          v_parts = get_version_parts(version)

          v_parts.each do |part|
            UI.user_error!('Version value can only contains numbers.') unless is_int?(part)
          end

          "#{v_parts[MAJOR_NUMBER]}.#{v_parts[MINOR_NUMBER]}.#{v_parts[HOTFIX_NUMBER]}.#{v_parts[BUILD_NUMBER]}"
        end

        # Check if a string is an integer
        #
        # @param [String] string The string to test
        #
        # @return [Bool] true if the string is representing an integer value, false if not
        #
        def self.is_int?(string)
          true if Integer(string) rescue false
        end
      end
    end
  end
end
