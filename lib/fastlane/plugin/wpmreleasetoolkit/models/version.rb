module Fastlane
  module Helper
    RC_DELIMITERS = %w[
      rc
      beta
      b
    ].freeze

    class Version
      include Comparable
      attr :major, :minor, :patch, :rc

      def initialize(major:, minor:, patch: 0, rc_number: nil)
        @major = major
        @minor = minor
        @patch = patch
        @rc = rc_number
      end

      # Create a new Version object based on a given string.
      #
      # Can parse a variety of different two, three, and four-segment version numbers,
      # including:
      # - x.y
      # - x.yrc1
      # - x.y.rc1
      # - x.y-rc1
      # - x.y.rc.1
      # - x.y-rc-1
      # - x.y.z
      # - x.y.zrc1
      # - x.y.z.rc1
      # - x.y.z-rc1
      # - x.y.z.rc.1
      # - x.y.z-rc-1
      # - Any of the above with `v` prepended
      #
      def self.create(string)
        string = string.downcase
        string = string.delete_prefix('v') if string.start_with?('v')

        components = string
                     .split('.')
                     .map { |component| component.remove('-') }
                     .delete_if { |component| component == 'rc' }

        return nil if components.length < 2

        # Turn RC version codes into simple versions
        if components.last.include? 'rc'
          rc_segments = VersionHelpers.rc_segments_from_string(components.last)
          components.delete_at(components.length - 1)
          components = VersionHelpers.combine_components_and_rc_segments(components, rc_segments)
        end

        # Validate our work
        return nil if components.any? { |component| !VersionHelpers.string_is_valid_int(component) }

        # If this is a simple version string, process it early
        major = components.first.to_i
        minor = components.second.to_i
        patch = components.third.to_i

        # Simple two-segment version numbers can exit here
        return Version.new(major: major, minor: minor) if components.length == 2

        # Simple three-segment version numbers can exit here
        return Version.new(major: major, minor: minor, patch: patch) if components.length == 3

        # Simple four-segment version numbers can exit here
        return Version.new(major: major, minor: minor, patch: patch, rc_number: components.fourth.to_i) if components.length == 4
      end

      # Create a new Version object based on a given string.
      #
      # Raises if the string is invalid
      def self.create!(string)
        version = create(string)
        raise "Invalid Version: #{string}" if version.nil?

        version
      end

      # Returns a formatted string suitable for use as an Android Version Name
      def android_version_name
        return [@major, @minor].join('.') if @patch.zero? && @rc.nil?
        return [@major, @minor, @patch].join('.') if !@patch.zero? && rc.nil?
        return [@major, "#{@minor}-rc-#{@rc}"].join('.') if @patch.zero? && !rc.nil?

        return [@major, @minor, "#{@patch}-rc-#{@rc}"].join('.')
      end

      # Returns a formatted string suitable for use as an Android Version Code
      def android_version_code(prefix: 1)
        [
          '1',
          @major,
          format('%02d', @minor),
          format('%02d', @patch),
          format('%02d', @rc || 0),
        ].join
      end

      # Returns a formatted string suitable for use as an iOS Version Number
      def ios_version_number
        return [@major, @minor, @patch, @rc || 0].join('.')
      end

      # Returns a string suitable for comparing two version objects
      #
      # This method has no version number padding, so its likely to have collisions
      def raw_version_code
        [@major, @minor, @patch, @rc || 0].join.to_i
      end

      # Is this version number a patch version?
      def patch?
        !@patch.zero?
      end

      # Is this version number a prerelease version?
      def prerelease?
        !@rc.nil?
      end

      # Derive the next major version from this version number
      def next_major_version
        Version.new(
          major: @major + 1,
          minor: 0
        )
      end

      # Derive the next minor version from this version number
      def next_minor_version
        major = @major
        minor = @minor

        if minor == 9
          major += 1
          minor = 0
        else
          minor += 1
        end

        Version.new(
          major: major,
          minor: minor
        )
      end

      # Derive the next patch version from this version number
      def next_patch_version
        Version.new(
          major: @major,
          minor: @minor,
          patch: @patch + 1
        )
      end

      # Derive the next rc version from this version number
      def next_rc_version
        rc = @rc
        rc = 0 if rc.nil?

        Version.new(
          major: @major,
          minor: @minor,
          patch: @patch,
          rc_number: rc + 1
        )
      end

      # Is this version the same as another version, just with different RC codes?
      def is_different_rc_of(other)
        return false unless other.is_a?(Version)

        return other.major == @major && other.minor == @minor && other.patch == @patch
      end

      # Is this version the same as another version, just with a different patch version?
      def is_different_patch_of(other)
        return false unless other.is_a?(Version)

        return other.major == @major && other.minor == @minor
      end

      def ==(other)
        return false unless other.is_a?(Version)

        raw_version_code == other.raw_version_code
      end

      def equal?(other)
        self == other
      end

      def <=>(other)
        raw_version_code <=> other.raw_version_code
      end
    end

    # A collection of helpers for the `Version.create` method that extract some of the tricky code
    # that's nice to be able to test in isolation – in practice, this is private API and you *probably*
    # don't want to use it for other things.
    module VersionHelpers
      # Determines whether the given string is a valid integer.
      #
      # Examples:
      # - 00  => true
      # - 01  => true
      # - 1   => true
      # - rc  => false
      # See the `version_helpers_spec` for more test cases.
      #
      # @param string String The string to check.
      # @return bool `true` if the given string is a valid integer. `false` if not.
      def self.string_is_valid_int(string)
        return true if string.count('0') == string.length

        # Remove any leading zeros
        string = string.delete_prefix('0')

        return string.to_i.to_s == string
      end

      # Extracts all integers (delimited by anything non-integer value) from a given string
      #
      # @param string String The string to check.
      # @return [int] The integers contained within the string
      def self.extract_ints_from_string(string)
        string.scan(/\d+/)
      end

      # Parses release candidate number (and potentially minor or patch version depending on how the
      # version code is formatted) from a given string. This can take a variety of forms because the
      # release candidate segment of a version string can be formatted in a lot of different ways.
      #
      # Examples:
      # - 00  =>  ['0']
      # - rc1  => ['1']
      # - 5rc1 => ['5','1']
      # See the `version_helpers_spec` for more test cases.
      #
      # @param string String The string to parse.
      # @return [string] The leading and trailing digits from the version segment string
      def self.rc_segments_from_string(string)
        # If the string is all zeros, return zero
        return ['0'] if string.scan(/0/).length == string.length

        extract_ints_from_string(string)
      end

      # Combines the non-RC version string components with the RC segments extracted by `rc_segments_from_string`.
      #
      # Because this method needs to be able to assemble the version segments and release candidate segments into a
      # coherent version based on a variety of input formats, the implementation looks pretty complex, but it's covered
      # by a comprehensive test suite to validate that it does, in fact, work.
      #
      # Examples:
      # - [1.0], [1]  =>  ['1','0', '0', '1']
      # - [1.0], [2,1]  =>  ['1','0', '2', '1']
      # See the `version_helpers_spec` for more test cases.
      #
      # @param components [string] The version string components (without the RC segments)
      # @param rc_segments [string] The return value from `rc_segments_from_string`
      # @return [string] An array of stringified integer version components in `major.minor.patch.rc` order
      def self.combine_components_and_rc_segments(components, rc_segments)
        case true # rubocop:disable Lint/LiteralAsCondition
        when components.length == 1 && rc_segments.length == 2
          return [components.first, rc_segments.first, '0', rc_segments.last]
        when components.length == 2 && rc_segments.length == 1
          return [components.first, components.second, '0', rc_segments.first]
        when components.length == 2 && rc_segments.length == 2
          return [components.first, components.second, rc_segments.first, rc_segments.last]
        when components.length == 3 && rc_segments.length == 1
          return [components.first, components.second, components.third, rc_segments.first]
        end

        raise "Invalid components: #{components.inspect} or rc_segments: #{rc_segments.inspect}"
      end
    end
  end
end
