module Fastlane
  module Helper
    module Android
      # A module containing helper methods to manipulate/extract/bump Android version strings in gradle files
      #
      module VersionHelper
        # The key used in internal version Hash objects to hold the versionName value
        VERSION_NAME = 'name'.freeze
        # The key used in internal version Hash objects to hold the versionCode value
        VERSION_CODE = 'code'.freeze
        # The index for the major version number part
        MAJOR_NUMBER = 0
        # The index for the minor version number part
        MINOR_NUMBER = 1
        # The index for the hotfix version number part
        HOTFIX_NUMBER = 2
        # The suffix used in the versionName for RC (beta) versions
        RC_SUFFIX = '-rc'.freeze

        # Extract the version name and code from the release version of the app from `version.properties file`
        #
        # @return [Hash] A hash with 2 keys "name" and "code" containing the extracted version name and code, respectively
        #
        def self.get_release_version(version_properties_path:)
          get_version_from_properties(version_properties_path: version_properties_path)
        end

        # Extract the version name and code from the `version.properties` file in the project root
        #
        # @param [Boolean] is_alpha true if the alpha version should be returned, false otherwise
        #
        # @return [Hash] A hash with 2 keys "name" and "code" containing the extracted version name and code, respectively
        #
        def self.get_version_from_properties(version_properties_path:, is_alpha: false)
          return nil unless File.exist?(version_properties_path)

          version_name_key = is_alpha ? 'alpha.versionName' : 'versionName'
          version_code_key = is_alpha ? 'alpha.versionCode' : 'versionCode'

          text = File.read(version_properties_path)
          name = text.match(/#{version_name_key}=(\S*)/m)&.captures&.first
          code = text.match(/#{version_code_key}=(\S*)/m)&.captures&.first

          name.nil? || code.nil? ? nil : { VERSION_NAME => name, VERSION_CODE => code.to_i }
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
          v = calc_next_release_base_version(VERSION_NAME => version, VERSION_CODE => nil)
          v[VERSION_NAME]
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

        # Determines if a version name corresponds to a hotfix
        #
        # @param [String] version The version number to test
        #
        # @return [Bool] True if the version number has a non-zero 3rd component, meaning that it is a hotfix version.
        #
        def self.is_hotfix?(version)
          return false if is_alpha_version?(version)

          vp = get_version_parts(version[VERSION_NAME])
          (vp.length > 2) && (vp[HOTFIX_NUMBER] != 0)
        end

        # Update the `version.properties` file with new `versionName` and `versionCode` values
        #
        # @param [Hash] new_version_beta The version hash for the beta, containing values for keys "name" and "code"
        # @param [Hash] new_version_alpha The version hash for the alpha , containing values for keys "name" and "code"
        #
        def self.update_versions(new_version_beta, new_version_alpha, version_properties_path:)
          raise "File at #{version_properties_path} does not exist." unless File.exist?(version_properties_path)

          replacements = {
            versionName: (new_version_beta || {})[VERSION_NAME],
            versionCode: (new_version_beta || {})[VERSION_CODE],
            'alpha.versionName': (new_version_alpha || {})[VERSION_NAME],
            'alpha.versionCode': (new_version_alpha || {})[VERSION_CODE]
          }
          content = File.read(version_properties_path)
          content.gsub!(/^(.*) ?=.*$/) do |line|
            key = Regexp.last_match(1).to_sym
            value = replacements[key]
            value.nil? ? line : "#{key}=#{value}"
          end
          File.write(version_properties_path, content)
        end

        # Extract the value of a import key from build.gradle
        #
        # @param [String] import_key The key to look for
        # @return [String] The value of the key, or nil if not found
        #
        def self.get_library_version_from_gradle_config(build_gradle_path:, import_key:)
          return nil unless File.exist?(build_gradle_path)

          File.open(build_gradle_path, 'r') do |f|
            text = f.read
            text.match(/^\s*(?:\w*\.)?#{Regexp.escape(import_key)}\s*=\s*['"](.*?)["']/m)&.captures&.first
          end
        end

        #----------------------------------------

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
          parts
        end
      end
    end
  end
end
