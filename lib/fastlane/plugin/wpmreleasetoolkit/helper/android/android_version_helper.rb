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
        def self.get_public_version
          version = get_release_version
          vp = get_version_parts(version[VERSION_NAME])
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}" unless is_hotfix?(version)

          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end

        # Extract the version name and code from the `vanilla` flavor of the `$PROJECT_NAME/build.gradle file`
        #   or for the defaultConfig if `HAS_ALPHA_VERSION` is not defined.
        #
        # @env HAS_ALPHA_VERSION If set (with any value), indicates that the project uses `vanilla` flavor.
        #
        # @return [Hash] A hash with 2 keys "name" and "code" containing the extracted version name and code, respectively
        #
        def self.get_release_version
          section = ENV['HAS_ALPHA_VERSION'].nil? ? 'defaultConfig' : 'vanilla {'
          gradle_path = self.gradle_path
          name = get_version_name_from_gradle_file(gradle_path, section)
          code = get_version_build_from_gradle_file(gradle_path, section)
          return { VERSION_NAME => name, VERSION_CODE => code }
        end

        # Extract the version name and code from the `defaultConfig` of the `$PROJECT_NAME/build.gradle` file
        #
        # @return [Hash] A hash with 2 keys `"name"` and `"code"` containing the extracted version name and code, respectively,
        #                or `nil` if `$HAS_ALPHA_VERSION` is not defined.
        #
        def self.get_alpha_version
          return nil if ENV['HAS_ALPHA_VERSION'].nil?

          section = 'defaultConfig'
          gradle_path = self.gradle_path
          name = get_version_name_from_gradle_file(gradle_path, section)
          code = get_version_build_from_gradle_file(gradle_path, section)
          return { VERSION_NAME => name, VERSION_CODE => code }
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
        # @param [Hash] beta_version The version hash for the beta (vanilla flavor), containing values for keys "name" and "code"
        # @param [Hash] alpha_version The version hash for the alpha (defaultConfig), containing values for keys "name" and "code",
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
          v = self.calc_next_release_base_version({ VERSION_NAME => version, VERSION_CODE => nil })
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
          if (vp[MINOR_NUMBER] == 10)
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
          nv = calc_next_release_base_version({ VERSION_NAME => version[VERSION_NAME], VERSION_CODE => alpha_version.nil? ? version[VERSION_CODE] : [version[VERSION_CODE], alpha_version[VERSION_CODE]].max })
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
          if (vp[MINOR_NUMBER] == 0)
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
        def self.bump_version_release
          # Bump release
          current_version = get_release_version()
          UI.message("Current version: #{current_version[VERSION_NAME]}")
          new_version = calc_next_release_base_version(current_version)
          UI.message("New version: #{new_version[VERSION_NAME]}")
          verified_version = verify_version(new_version[VERSION_NAME])

          return verified_version
        end

        # Update the `build.gradle` file with new `versionName` and `versionCode` values, both or the `defaultConfig` and `vanilla` flavors
        #
        # @param [Hash] new_version_beta The version hash for the beta (vanilla flavor), containing values for keys "name" and "code"
        # @param [Hash] new_version_alpha The version hash for the alpha (defaultConfig), containing values for keys "name" and "code"
        # @env HAS_ALPHA_VERSION If set (with any value), indicates that the project uses `vanilla` flavor.
        #
        def self.update_versions(new_version_beta, new_version_alpha)
          self.update_version(new_version_beta, ENV['HAS_ALPHA_VERSION'].nil? ? 'defaultConfig' : 'vanilla {')
          self.update_version(new_version_alpha, 'defaultConfig') unless new_version_alpha.nil?
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

        # Extract the versionName from a build.gradle file
        #
        # @param [String] file_path The path to the `.gradle` file
        # @param [String] section The name of the section we expect the keyword to be in, e.g. "defaultConfig" or "vanilla"
        #
        # @return [String] The value of the versionName attribute as found in the build.gradle file and for this section.
        #
        def self.get_version_name_from_gradle_file(file_path, section)
          res = get_keyword_from_gradle_file(file_path, section, 'versionName')
          res = res.tr('\"', '') unless res.nil?
          return res
        end

        # Extract the versionCode rom a build.gradle file
        #
        # @param [String] file_path The path to the `.gradle` file
        # @param [String] section The name of the section we expect the keyword to be in, e.g. "defaultConfig" or "vanilla"
        #
        # @return [String] The value of the versionCode attribute as found in the build.gradle file and for this section.
        #
        def self.get_version_build_from_gradle_file(file_path, section)
          res = get_keyword_from_gradle_file(file_path, section, 'versionCode')
          return res.to_i
        end

        # Extract the value for a specific keyword in a specific section of a `.gradle` file
        #
        # @todo: This implementation is very fragile. This should be done parsing the file in a proper way.
        #        Leveraging gradle itself is probably the easiest way.
        #
        # @param [String] file_path The path of the `.gradle` file to extract the value from
        # @param [String] section The name of the section from which we want to extract this keyword from. For example `defaultConfig` or `myFlavor`
        # @param [String] keyword The keyword (key name) we want the value for
        #
        # @return [String] Returns the value for that keyword in the section of the `.gradle` file, or nil if not found.
        #
        def self.get_keyword_from_gradle_file(file_path, section, keyword)
          found_section = false
          File.open(file_path, 'r') do |file|
            file.each_line do |line|
              if !found_section
                if line.include?(section)
                  found_section = true
                end
              else
                if line.include?(keyword) && !line.include?("\"#{keyword}\"") && !line.include?("P#{keyword}")
                  return line.split(' ')[1]
                end
              end
            end
          end
          return nil
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
            if (!is_int?(part)) then
              UI.user_error!('Version value can only contains numbers.')
            end
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

        # The path to the build.gradle file for the project.
        #
        # @env PROJECT_ROOT_FOLDER The path to the root of the project (the folder containing the `.git` directory).
        # @env PROJECT_NAME The name of the project, i.e. the name of the subdirectory containing the project's `build.gradle` file.
        #
        # @return [String] The path of the `build.gradle` file inside the project subfolder in the project's repo
        #
        def self.gradle_path
          UI.user_error!("You need to set the \`PROJECT_ROOT_FOLDER\` environment variable to the path to the project's root") if ENV['PROJECT_ROOT_FOLDER'].nil?
          UI.user_error!("You need to set the \`PROJECT_NAME\` environment variable to the relative path to the project subfolder name") if ENV['PROJECT_NAME'].nil?
          File.join(ENV['PROJECT_ROOT_FOLDER'], ENV['PROJECT_NAME'], 'build.gradle')
        end

        # Update both the versionName and versionCode of the build.gradle file to the specified version.
        #
        # @param [Hash] version The version hash, containing values for keys "name" and "code"
        # @param [String] section The name of the section to update in the build.gradle file, e.g. "defaultConfig" or "vanilla"
        #
        # @todo This implementation is very fragile. This should be done parsing the file in a proper way.
        #       Leveraging gradle itself is probably the easiest way.
        #
        def self.update_version(version, section)
          gradle_path = self.gradle_path
          temp_file = Tempfile.new('fastlaneIncrementVersion')
          found_section = false
          version_updated = 0
          File.open(gradle_path, 'r') do |file|
            file.each_line do |line|
              if !found_section
                temp_file.puts line
                if (line.include? section)
                  found_section = true
                end
              else
                if (version_updated < 2)
                  if line.include?('versionName') && !line.include?('"versionName"') && !line.include?('PversionName')
                    version_name = line.split(' ')[1].tr('\"', '')
                    line.sub!(version_name, version[VERSION_NAME].to_s)
                    version_updated = version_updated + 1
                  end

                  if (line.include? 'versionCode')
                    version_code = line.split(' ')[1]
                    line.sub!(version_code, version[VERSION_CODE].to_s)
                    version_updated = version_updated + 1
                  end
                end
                temp_file.puts line
              end
            end
            file.close
          end
          temp_file.rewind
          temp_file.close
          FileUtils.mv(temp_file.path, gradle_path)
          temp_file.unlink
        end
      end
    end
  end
end
