module ReleaseToolkit
  module Models
    module Android
      # A model representing an Android VersionName
      #
      # Can represent an alpha, beta or final version, with or without a hotfix number
      # Provide utility methods to inspect the type of version it represents and to bump versions
      #
      class VersionName
        attr_reader :major, :minor, :hotfix
        attr_reader :prerelease_num

        # Creates a new version name of one of the following form:
        # - final version (`"1.2"` or `"1.2.3"`) if `prerelease_num` is `nil`.
        # - beta version (`"1.2-rc-4"` or `"1.2.3-rc-4"`) if `prerelease_num` is non-nil but at least major and minor are provided.
        # - alpha version (`"alpha-4"`) if `prerelease_num` is non-nil but neither major, minor and hotfix are provided.
        #
        # @param [Integer, NilClass] major The major version number, or nil for an alpha version
        # @param [Integer, NilClass] minor The minor version number, or nil for an alpha version
        # @param [Integer, NilClass] hotfix The hotfix/patch version number, or nil for an alpha version or if not a hotfix
        # @param [Integer, NilClass] prerelease_num The alpha or beta version number, or nil if it's a final version
        #
        def initialize(major:, minor:, hotfix: nil, prerelease_num: nil)
          raise 'if you provide major, you should also provide minor' if !major.nil? && minor.nil?
          raise 'if you provide minor, you should also provide major' if major.nil? && !minor.nil?
          raise 'if you provide hotfix, you should also provide major and minor' if !hotfix.nil? && (major.nil? || minor.nil?)

          @major = major.nil? ? nil : Integer(major)
          @minor = minor.nil? ? nil : Integer(minor)
          @hotfix = hotfix.nil? ? nil : Integer(hotfix)
          @prerelease_num = prerelease_num.nil? ? nil : Integer(prerelease_num)
        end
        private_class_method :new # You should use one of the new_* methods below instead.

        # Creates a new instance representing an alpha version (`alpha-1234`)
        #
        # @param [Integer] number The alpha version number
        #
        # @return [Fastlane::Helper::Android::VersionName]
        #
        def self.new_alpha(number:)
          new(major: nil, minor: nil, hotfix: nil, prerelease_num: number)
        end

        # Creates a new instance representing a beta version (`1.2-rc-4` or `1.2.3-rc-4`)
        #
        # @param [Integer] major The major version number
        # @param [Integer] minor The minor version number
        # @param [Integer, NilClass] hotfix The hotfix version number, or nil if it is not a hotfix
        # @param [Integer] beta The beta number
        #
        # @return [Fastlane::Helper::Android::VersionName]
        #
        def self.new_beta(major:, minor:, hotfix: nil, beta:)
          new(major: major, minor: minor, hotfix: hotfix, prerelease_num: beta)
        end

        # Creates a new instance representing a final version (`1.2` or `1.2.3`)
        #
        # @param [Integer] major The major version number
        # @param [Integer] minor The minor version number
        # @param [Integer, NilClass] hotfix The hotfix version number, or nil if it is not a hotfix
        #
        # @return [Fastlane::Helper::Android::VersionName]
        #
        def self.new_final(major:, minor:, hotfix: nil)
          new(major: major, minor: minor, hotfix: hotfix, prerelease_num: nil)
        end

        # Creates a new instance rom a string representation
        #
        # @param [String] string The string representing the version name to parse
        #
        # @return [Fastlane::Helper::Android::VersionName]
        # @raise [RuntimeError] if the version does not match any known format
        #
        def self.from_string(string)
          return nil if string.nil?
          parts = string.split('-')
          if parts.count == 2 && parts[0] == 'alpha'
            new_alpha(number: parts[1].to_i || 0)
          else
            (major, minor, hotfix) = parts[0].split('.').map { |n| Integer(n) }
            if parts.count >= 3 && parts[1] == 'rc'
              new_beta(major: major.to_i, minor: minor.to_i, hotfix: hotfix, beta: parts[2].to_i)
            elsif parts.count == 1
              new_final(major: major, minor: minor, hotfix: hotfix)
            else
              raise "Invalid VersionName string: #{name}"
            end
          end
        end

        # Checks if this represents an alpha version, e.g. `"alpha-1234"`
        #
        # @return [TrueClass, FalseClass]
        def is_alpha?
          !prerelease_num.nil? && [major, minor, hotfix].all?(&:nil?)
        end

        # Checks if this represents a beta (aka rc) version, e.g. `"1.2-rc-4"` or `"1.2.3-rc-4"`
        #
        # @return [TrueClass, FalseClass]
        def is_beta?
          !prerelease_num.nil? && !major.nil? && !minor.nil?
        end

        # Checks if this represents a final version (hotfix or not, but at least neither alpha nor beta), e.g. `"1.2"` or `"1.2.3"`
        #
        # @return [TrueClass, FalseClass]
        def is_final?
          prerelease_num.nil?
        end

        # Checks if this represents a hotfix (i.e. hotfix value is non-nil and >0)
        #
        # @return [TrueClass, FalseClass]
        def is_hotfix?
          !hotfix.nil? && hotfix != 0
        end

        # @return [String] The string representation of the VersionName
        #
        def to_s
          if is_alpha?
            "alpha-#{prerelease_num}"
          else
            base = [major, minor, hotfix].compact.join('.')
            if is_beta?
              "#{base}-rc-#{prerelease_num}"
            else
              base
            end
          end
        end
      end
    end
  end
end
