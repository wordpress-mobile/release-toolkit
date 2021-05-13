module Fastlane
  module Helper
    module Android
      # A module containing helper methods to manipulate/extract/bump Android version strings in gradle files
      #
      module VersionHelper
        # The key used in internal version Hash objects to hold the versionName value
        VERSION_NAME = 'name'
        # The key used in internal version Hash objects to hold the versionCode value
        VERSION_CODE = 'code'
        # The index for the major version number part
        MAJOR_NUMBER = 0
        # The index for the minor version number part
        MINOR_NUMBER = 1
        # The index for the hotfix version number part
        HOTFIX_NUMBER = 2
        # The prefix used in front of the versionName for alpha versions
        ALPHA_PREFIX = 'alpha-'
        # The suffix used in the versionName for RC (beta) versions
        RC_SUFFIX = '-rc'

        # Returns the public-facing version string.
        #
        # @example
        #    "1.2" # Assuming build.gradle contains versionName "1.2"
        #    "1.2" # Assuming build.gradle contains versionName "1.2.0"
        #    "1.2.3" # Assuming build.gradle contains versionName "1.2.3"
        #
        # @return [String] The public-facing version number, extracted from the `versionName` of the `build.gradle` file.
        #         - If this version is a hotfix (more than 2 parts and 3rd part is non-zero), returns the "X.Y.Z" formatted string
        #         - Otherwise (not a hotfix / 3rd part of version is 0), returns "X.Y" formatted version number
        #
        def self.get_public_version(app)
          version = get_version_from_properties(app, false)
          vp = get_version_parts(version[VERSION_NAME])
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}" unless is_hotfix?(version)

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end

        # Extract the version name and code from the release version of the app from `version.properties file`
        #
        # @return [Hash] A hash with 2 keys "name" and "code" containing the extracted version name and code, respectively
        #
        def self.get_release_version(app)
          return get_version_from_properties(app, false)
        end

        # Extract the version name and code from the `version.properties` file in the project root
        #
        # @return [Hash] A hash with 2 keys "name" and "code" containing the extracted version name and code, respectively
        #
        def self.get_version_from_properties(product_name, is_alpha)
          version_name_key = "#{product_name}.#{is_alpha ? 'alpha.' : ''}versionName"
          version_code_key = "#{product_name}.#{is_alpha ? 'alpha.' : ''}versionCode"

          properties_file_path = File.join(ENV['PROJECT_ROOT_FOLDER'] || '.', 'version.properties')

          return nil unless File.exist?(properties_file_path)

          File.open(properties_file_path, 'r') do |f|
            text = f.read
            name = text.match(/#{version_name_key}=(\S*)/m)&.captures&.first
            code = text.match(/#{version_code_key}=(\S*)/m)&.captures&.first

            f.close

            return nil if name.nil? || code.nil?

            return { VERSION_NAME => name, VERSION_CODE => code.to_i }
          end
        end

        # Extract the version name and code from the `version.properties` file in the project root
        #
        # @return [Hash] A hash with 2 keys `"name"` and `"code"` containing the extracted version name and code, respectively,
        #                or `nil` if `$HAS_ALPHA_VERSION` is not defined.
        #
        def self.get_alpha_version(app)
          return get_version_from_properties(app, true)
        end

        # Determines if a version name corresponds to an alpha version (starts with `"alpha-"`` prefix)
        #
        # @param [String] version The version name to check
        #
        # @return [Bool] true if the version name starts with the `ALPHA_PREFIX`, false otherwise.
        #
        # @private
        #
        def self.is_alpha_version?(version)
          version[VERSION_NAME].start_with?(ALPHA_PREFIX)
        end

        # Check if this versionName corresponds to a beta, i.e. contains some `-rc` suffix
        #
        # @param [String] version The versionName string to check for
        #
        # @return [Bool] True if the version string contains `-rc`, indicating it is a beta version.
        #
        def self.is_beta_version?(version)
          version[VERSION_NAME].include?(RC_SUFFIX)
        end

        # Returns the version name and code to use for the final release.
        #
        # - The final version name corresponds to the beta's versionName, without the `-rc` suffix
        # - The final version code corresponds to the versionCode for the alpha (or for the beta if alpha_version is nil) incremented by one.
        #
        # @param [Hash] beta_version The version hash for the beta, containing values for keys "name" and "code"
        # @param [Hash] alpha_version The version hash for the alpha, containing values for keys "name" and "code",
        #                             or `nil` if no alpha version to consider.
        #
        # @return [Hash] A version hash with keys "name" and "code", containing the version name and code to use for final release.
        #
        def self.calc_final_release_version(beta_version, alpha_version)
          version_name = beta_version[VERSION_NAME].split('-')[0]
          version_code = alpha_version.nil? ? beta_version[VERSION_CODE] + 1 : alpha_version[VERSION_CODE] + 1

          { VERSION_NAME => version_name, VERSION_CODE => version_code }
        end

        # Returns the version name and code to use for the next alpha.
        #
        # - The next version name corresponds to the `alpha_version`'s name incremented by one (alpha-42 => alpha-43)
        # - The next version code corresponds to the `version`'s code incremented by one.
        #
        # @param [Hash] version The version hash for the current beta or release, containing values for keys "name" and "code"
        # @param [Hash] alpha_version The version hash for the current alpha (defaultConfig), containing values for keys "name" and "code"
        #
        # @return [Hash] A version hash with keys "name" and "code", containing the version name and code to use for final release.
        #
        def self.calc_next_alpha_version(version, alpha_version)
          # Bump alpha name
          alpha_number = alpha_version[VERSION_NAME].sub(ALPHA_PREFIX, '')
          alpha_name = "#{ALPHA_PREFIX}#{alpha_number.to_i() + 1}"

          # Bump alpha code
          alpha_code = version[VERSION_CODE] + 1

          { VERSION_NAME => alpha_name, VERSION_CODE => alpha_code }
        end

        # Compute the version name and code to use for the next beta (`X.Y.Z-rc-N`).
        #
        # - The next version name corresponds to the `version`'s name with the value after the `-rc-` suffix incremented by one,
        #     or with `-rc-1` added if there was no previous rc suffix (if `version` was not a beta but a release)
        # - The next version code corresponds to the `alpha_version`'s (or `version`'s if `alpha_version` is nil) code, incremented by one.
        #
        # @example
        #   calc_next_beta_version({"name": "1.2.3", "code": 456}) #=> {"name": "1.2.3-rc-1", "code": 457}
        #   calc_next_beta_version({"name": "1.2.3-rc-2", "code": 456}) #=> {"name": "1.2.3-rc-3", "code": 457}
        #   calc_next_beta_version({"name": "1.2.3", "code": 456}, {"name": "alpha-1.2.3", "code": 457}) #=> {"name": "1.2.3-rc-1", "code": 458}
        #
        # @param [Hash] version The version hash for the current beta or release, containing values for keys "name" and "code"
        # @param [Hash] alpha_version The version hash for the alpha, containing values for keys "name" and "code",
        #                             or `nil` if no alpha version to consider.
        #
        # @return [Hash] A hash with keys `"name"` and `"code"` containing the next beta version name and code.
        #
        def self.calc_next_beta_version(version, alpha_version = nil)
          # Bump version name
          beta_number = is_beta_version?(version) ? version[VERSION_NAME].split('-')[2].to_i + 1 : 1
          version_name = "#{version[VERSION_NAME].split('-')[0]}#{RC_SUFFIX}-#{beta_number}"

          # Bump version code
          version_code = alpha_version.nil? ? version[VERSION_CODE] + 1 : alpha_version[VERSION_CODE] + 1
          { VERSION_NAME => version_name, VERSION_CODE => version_code }
        end

        # Compute the version name to use for the next release (`"X.Y"`).
        #
        # @param [String] version The version name (string) to increment
        #
        # @return [String] The version name for the next release
        #
        def self.calc_next_release_short_version(version)
          v = self.calc_next_release_base_version(VERSION_NAME => version, VERSION_CODE => nil)
          return v[VERSION_NAME]
        end

        # Compute the next release version name for the given version, without incrementing the version code
        #
        #  - The version name sees its minor version part incremented by one (and carried to next major if it reaches 10)
        #  - The version code is unchanged. This method is intended to be called internally by other methods taking care of the version code bump.
        #
        # @param [Hash] version A version hash, with keys `"name"` and `"code"`, containing the version to increment
        #
        # @return [Hash] Hash containing the next release version name ("X.Y") and code.
        #
        def self.calc_next_release_base_version(version)
          version_name = remove_beta_suffix(version[VERSION_NAME])
          vp = get_version_parts(version_name)
          vp[MINOR_NUMBER] += 1
          if vp[MINOR_NUMBER] == 10
            vp[MAJOR_NUMBER] += 1
            vp[MINOR_NUMBER] = 0
          end

          { VERSION_NAME => "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}", VERSION_CODE => version[VERSION_CODE] }
        end

        # Compute the name of the next version to use after code freeze, by incrementing the current version name and making it a `-rc-1`
        #
        # @example
        #   calc_next_release_version({"name": "1.2", "code": 456}) #=> {"name":"1.3-rc-1", "code": 457}
        #   calc_next_release_version({"name": "1.2.3", "code": 456}) #=> {"name":"1.3-rc-1", "code": 457}
        #   calc_next_release_version({"name": "1.2", "code": 456}, {"name":"alpha-1.2", "code": 457}) #=> {"name":"1.3-rc-1", "code": 458}
        #
        # @param [Hash] version The current version hash, with keys `"name"` and `"code"`
        # @param [Hash] alpha_version The current alpha version hash, with keys `"name"` and `"code"`, or nil if no alpha version
        #
        # @return [Hash] The hash containing the version name and code to use after release cut
        #
        def self.calc_next_release_version(version, alpha_version = nil)
          nv = calc_next_release_base_version(VERSION_NAME => version[VERSION_NAME], VERSION_CODE => alpha_version.nil? ? version[VERSION_CODE] : [version[VERSION_CODE], alpha_version[VERSION_CODE]].max)
          calc_next_beta_version(nv)
        end

        # Compute the name and code of the next hotfix version.
        #
        # @param [String] hotfix_version_name The next version name we want for the hotfix
        # @param [String] hotfix_version_code The next version code we want for the hotfix
        #
        # @return [Hash] The predicted next hotfix version, as a Hash containing the keys `"name"` and `"code"`
        #
        def self.calc_next_hotfix_version(hotfix_version_name, hotfix_version_code)
          { VERSION_NAME => hotfix_version_name, VERSION_CODE => hotfix_version_code }
        end

        # Compute the name of the previous release version, by decrementing the minor version number
        #
        # @example
        #    calc_prev_release_version("1.2") => "1.1"
        #    calc_prev_release_version("1.2.3") => "1.1"
        #    calc_prev_release_version("3.0") => "2.9"
        #
        # @param [String] version The version string to decrement
        #
        # @return [String] A 2-parts version string "X.Y" corresponding to the guessed previous release version.
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

        # Determines if a version name corresponds to a hotfix
        #
        # @param [String] version The version number to test
        #
        # @return [Bool] True if the version number has a non-zero 3rd component, meaning that it is a hotfix version.
        #
        def self.is_hotfix?(version)
          return false if is_alpha_version?(version)

          vp = get_version_parts(version[VERSION_NAME])
          return (vp.length > 2) && (vp[HOTFIX_NUMBER] != 0)
        end

        # Prints the current and next release version names to stdout, then returns the next release version
        #
        # @return [String] The next release version name to use after bumping the currently used release version.
        #
        def self.bump_version_release(app)
          # Bump release
          return bump_version_for_app(app, false)
        end

        # Prints the current and next version names for a given section to stdout, then returns the next version
        #
        # @return [String] The next version name to use after bumping the currently used version.
        #
        def self.bump_version_for_app(app, is_alpha)
          # Bump release
          current_version = get_version_from_properties(app, is_alpha)
          UI.message("Current version: #{current_version[VERSION_NAME]}")
          new_version = calc_next_release_base_version(current_version)
          UI.message("New version: #{new_version[VERSION_NAME]}")
          verified_version = verify_version(new_version[VERSION_NAME])

          return verified_version
        end

        # Update the `version.properties` file with new `versionName` and `versionCode` values
        #
        # @param [Hash] new_version_beta The version hash for the beta, containing values for keys "name" and "code"
        # @param [Hash] new_version_alpha The version hash for the alpha , containing values for keys "name" and "code"
        #
        def self.update_versions(app, new_version_beta, new_version_alpha)
          new_version_name_beta_key = "#{app}.versionName"
          new_version_code_beta_key = "#{app}.versionCode"
          new_version_name_alpha_key = "#{app}.alpha.versionName"
          new_version_code_alpha_key = "#{app}.alpha.versionCode"
          Action.sh('./gradlew', 'updateVersionProperties', "-Pkey=#{new_version_name_beta_key}", "-Pvalue=#{new_version_beta[VERSION_NAME]}")
          Action.sh('./gradlew', 'updateVersionProperties', "-Pkey=#{new_version_code_beta_key}", "-Pvalue=#{new_version_beta[VERSION_CODE]}")
          Action.sh('./gradlew', 'updateVersionProperties', "-Pkey=#{new_version_name_alpha_key}", "-Pvalue=#{new_version_alpha[VERSION_NAME]}") unless new_version_alpha.nil?
          Action.sh('./gradlew', 'updateVersionProperties', "-Pkey=#{new_version_code_alpha_key}", "-Pvalue=#{new_version_alpha[VERSION_CODE]}") unless new_version_alpha.nil?
        end

        # Compute the name of the previous hotfix version.
        #
        # @param [String] version_name The current version name we want to decrement
        #
        # @return [String] The predicted previous hotfix version, in the form of "X.Y.Z", or "X.Y" if Z is 0.
        #         Corresponds to decrementing the 3rd component Z of the version, stripping it if it ends up being zero.
        #
        def self.calc_prev_hotfix_version_name(version_name)
          vp = get_version_parts(version_name)
          vp[HOTFIX_NUMBER] -= 1 unless vp[HOTFIX_NUMBER] == 0
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}" unless vp[HOTFIX_NUMBER] == 0

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        # Extract the value of a import key from build.gradle
        #
        # @param [String] import_key The key to look for
        # @return [String] The value of the key, or nil if not found
        #
        def self.get_library_version_from_gradle_config(import_key:)
          gradle_file_path = File.join(ENV['PROJECT_ROOT_FOLDER'] || '.', 'build.gradle')

          return nil unless File.exists?(gradle_file_path)

          File.open(gradle_file_path, 'r') do | f |
            text = f.read
            text.match(/^\s*(?:\w*\.)?#{Regexp.escape(import_key)}\s*=\s*['"](.*?)["']/m)&.captures&.first
          end
        end

        #----------------------------------------
        private

        # Remove the beta suffix (part after the `-`) from a version string
        #
        # @param [String] version The version string to remove the suffix from
        #
        # @return [String] The part of the version string without the beta suffix, i.e. the part before the first dash.
        #
        # @example remove_beta_suffix("1.2.3-rc.4") => "1.2.3"
        #
        def self.remove_beta_suffix(version)
          version.split('-')[0]
        end

        # Split a version string into its individual integer parts
        #
        # @param [String] version The version string to split, e.g. "1.2.3.4"
        #
        # @return [Array<Int>] An array of integers containing the individual integer parts of the version.
        #                      Always contains 3 items at minimum (0 are added to the end if the original string contains less than 3 parts)
        #
        def self.get_version_parts(version)
          parts = version.split('.').map(&:to_i)
          parts.fill(0, parts.length...3) # add 0 if needed to ensure array has at least 3 components
          return parts
        end

        # Ensure that a version string is correctly formatted (that is, each of its parts is a number) and returns the 2-parts version number
        #
        # @param [String] version The version string to verify
        #
        # @return [String] The "major.minor" version string, only with the first 2 components
        # @raise [UserError] If any of the parts of the version string is not a number
        #
        def self.verify_version(version)
          v_parts = get_version_parts(version)

          v_parts.each do |part|
            UI.user_error!('Version value can only contains numbers.') unless is_int?(part)
          end

          "#{v_parts[MAJOR_NUMBER]}.#{v_parts[MINOR_NUMBER]}"
        end

        # Check if a string is an integer.
        #
        # @param [String] string The string to test
        #
        # @return [Bool] true if the string is representing an integer value, false if not
        #
        def self.is_int? string
          true if Integer(string) rescue false
        end
      end
    end
  end
end
