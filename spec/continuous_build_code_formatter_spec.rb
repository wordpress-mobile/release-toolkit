# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::ContinuousBuildCodeFormatter do
  describe 'derives a versionCode' do
    it 'encodes major, minor and build number with the default build_digits (6)' do
      expect(described_class.new.build_code(major: 26, minor: 9, build_number: 84_231)).to eq(269_084_231)
    end

    it 'returns an Integer' do
      expect(described_class.new.build_code(major: 26, minor: 9, build_number: 84_231)).to be_a(Integer)
    end
  end

  describe 'monotonicity' do
    it 'increases with the build number within the same version' do
      formatter = described_class.new
      expect(formatter.build_code(major: 26, minor: 9, build_number: 84_232))
        .to be > formatter.build_code(major: 26, minor: 9, build_number: 84_231)
    end

    it 'increases across a version bump even when the build number also increases' do
      formatter = described_class.new
      expect(formatter.build_code(major: 27, minor: 0, build_number: 84_232))
        .to be > formatter.build_code(major: 26, minor: 9, build_number: 84_231)
    end
  end

  describe 'custom build_digits' do
    it 'applies the configured multiplier (10^build_digits)' do
      # (2 * 10 + 6) * 10^4 + 123 = 26 * 10_000 + 123 = 260_123
      expect(described_class.new(build_digits: 4).build_code(major: 2, minor: 6, build_number: 123)).to eq(260_123)
    end
  end

  # The build number is allowed to exceed 10^build_digits. The docstring guarantees ordering still
  # holds in that case (overflow "only costs human-readability, not ordering") *because* the build
  # number is globally monotonic. These lock that in — and guard against a future change such as
  # masking the build number with `% 10**build_digits`, which would silently break ordering.
  context 'when the build number overflows its reserved digits (10^build_digits)' do
    it 'still increases within the same version across the overflow boundary' do
      formatter = described_class.new(build_digits: 4) # 10^4 = 10_000
      # 269 * 10_000 + 10_000 = 2_700_000   vs   269 * 10_000 + 9_999 = 2_699_999
      expect(formatter.build_code(major: 26, minor: 9, build_number: 10_000))
        .to be > formatter.build_code(major: 26, minor: 9, build_number: 9_999)
    end

    it 'still increases across a version bump while both build numbers are past the overflow point' do
      formatter = described_class.new(build_digits: 4) # 10^4 = 10_000
      # 270 * 10_000 + 25_001 = 2_725_001   vs   269 * 10_000 + 25_000 = 2_715_000
      expect(formatter.build_code(major: 27, minor: 0, build_number: 25_001))
        .to be > formatter.build_code(major: 26, minor: 9, build_number: 25_000)
    end

    it 'can render identically to a later version once overflowed — the documented readability cost, which is harmless under a monotonic build number' do
      formatter = described_class.new(build_digits: 4) # 10^4 = 10_000
      # Overflow makes the digits ambiguous: 26.9 build 10_000 and 27.0 build 0 both come out as 2_700_000.
      # That's the "only costs human-readability" caveat — and it's safe because a globally monotonic
      # build number means (27, 0, build: 0) never *follows* (26, 9, build: 10_000); the counter only goes up.
      expect(formatter.build_code(major: 26, minor: 9, build_number: 10_000))
        .to eq(formatter.build_code(major: 27, minor: 0, build_number: 0))
    end
  end

  describe 'validation' do
    it 'raises when minor is greater than 9' do
      expect { described_class.new.build_code(major: 26, minor: 10, build_number: 1) }
        .to raise_error(/Minor version \(10\) must be 9 or lower/)
    end

    it 'raises when the derived code exceeds the Play Store maximum' do
      # (210 * 10 + 0) * 10^6 = 2_100_000_000; +1 tips over the cap.
      expect { described_class.new.build_code(major: 210, minor: 0, build_number: 1) }
        .to raise_error(/exceeds the maximum allowed Play Store versionCode \(2100000000\)/)
    end

    it 'does not raise when the derived code is exactly at the Play Store maximum' do
      expect(described_class.new.build_code(major: 210, minor: 0, build_number: 0)).to eq(2_100_000_000)
    end

    it 'raises when the derived code is not positive (all-zeros input)' do
      expect { described_class.new.build_code(major: 0, minor: 0, build_number: 0) }
        .to raise_error(/Derived build code \(0\) must be a positive integer/)
    end

    it 'rejects a non-integer build_digits' do
      expect { described_class.new(build_digits: '6') }
        .to raise_error(/`build_digits` must be an integer, got: String/)
    end

    it 'rejects a non-positive build_digits' do
      expect { described_class.new(build_digits: 0) }
        .to raise_error(/`build_digits` must be a positive integer, got: 0/)
    end

    %w[major minor build_number].each do |component|
      it "rejects a non-integer #{component} with a user-friendly error" do
        args = { major: 26, minor: 9, build_number: 84_231 }
        args[component.to_sym] = '1' # e.g. an unparsed value from an env var or file read
        expect { described_class.new.build_code(**args) }
          .to raise_error(/`#{component}` must be an integer, got: String/)
      end

      it "rejects a negative #{component}" do
        args = { major: 26, minor: 9, build_number: 84_231 }
        args[component.to_sym] = -1
        expect { described_class.new.build_code(**args) }
          .to raise_error(/`#{component}` must be a non-negative integer, got: -1/)
      end
    end
  end
end
