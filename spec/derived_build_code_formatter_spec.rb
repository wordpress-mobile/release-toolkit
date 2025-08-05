# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::DerivedBuildCodeFormatter do
  describe 'derives a build code from an AppVersion object' do
    context 'with default prefix (nil)' do
      it 'derives the build code from version numbers that are single digits' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        build_code_string = described_class.new.build_code(version: version)
        expect(build_code_string.to_s).to eq('1020304')
      end

      it 'derives the build code from version numbers that are two digits' do
        version = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
        build_code_string = described_class.new.build_code(version: version)
        expect(build_code_string.to_s).to eq('12345678')
      end
    end

    context 'with explicit prefix' do
      it 'derives the build code with prefix "2"' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        formatter = described_class.new(prefix: '2')
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('201020304')
      end

      it 'derives the build code with prefix "0" and trims leading zeros' do
        version = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
        formatter = described_class.new(prefix: '0')
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('12345678')
      end
    end

    context 'with empty prefix' do
      it 'derives the build code without prefix and trims leading zeros' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        formatter = described_class.new(prefix: '')
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('1020304')
      end

      it 'derives the build code without prefix for two-digit major version' do
        version = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
        formatter = described_class.new(prefix: '')
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('12345678')
      end

      it 'handles edge case with all zeros after removing leading zeros' do
        version = Fastlane::Models::AppVersion.new(0, 0, 0, 1)
        formatter = described_class.new(prefix: '')
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('1')
      end
    end

    context 'with nil prefix' do
      it 'treats nil prefix as empty string and derives build code without prefix' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        formatter = described_class.new(prefix: nil)
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('1020304')
      end

      it 'treats nil prefix as empty string for two-digit major version' do
        version = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
        formatter = described_class.new(prefix: nil)
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('12345678')
      end
    end
  end

  describe 'configurable digit counts' do
    context 'with custom digit counts' do
      it 'uses 1 digit for each component' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        formatter = described_class.new(prefix: '1', major_digits: 1, minor_digits: 1, patch_digits: 1, build_digits: 1)
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('11234')
      end

      it 'uses 2 digits for each component and pads with zeros' do
        # Test both large numbers and zero-padding in one test
        version_large = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
        formatter = described_class.new(prefix: '2', major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)
        expect(formatter.build_code(version: version_large).to_s).to eq('212345678')

        # Test zero-padding with smaller numbers
        version_small = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        expect(formatter.build_code(version: version_small).to_s).to eq('201020304')
      end

      it 'uses mixed digit counts' do
        version = Fastlane::Models::AppVersion.new(1, 23, 45, 678)
        formatter = described_class.new(prefix: '', major_digits: 1, minor_digits: 2, patch_digits: 2, build_digits: 3)
        build_code_string = formatter.build_code(version: version)
        # 1(1 digit) + 23(2 digits) + 45(2 digits) + 678(3 digits) = "12345678"
        expect(build_code_string.to_s).to eq('12345678')
      end

      it 'handles maximum values within digit limits' do
        version = Fastlane::Models::AppVersion.new(99, 99, 99, 99)
        formatter = described_class.new(prefix: '1', major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('199999999')
      end
    end

    context 'with empty prefix and custom digits' do
      it 'trims leading zeros correctly with 1-digit major' do
        version = Fastlane::Models::AppVersion.new(5, 12, 34, 56)
        formatter = described_class.new(prefix: '', major_digits: 1, minor_digits: 2, patch_digits: 2, build_digits: 2)
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('5123456')
      end

      it 'trims leading zeros correctly with larger number of major digits' do
        version = Fastlane::Models::AppVersion.new(7, 8, 9, 10)
        formatter = described_class.new(prefix: '', major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('7080910')
      end

      it 'handles edge case where all components start with zeros' do
        version = Fastlane::Models::AppVersion.new(0, 1, 2, 3)
        formatter = described_class.new(prefix: '', major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)
        build_code_string = formatter.build_code(version: version)
        # ''(empty prefix) + '00'(2 digits) + '01'(2 digits) + '02'(2 digits) + '03'(2 digits) = "00010203", trimmed to "10203"
        expect(build_code_string.to_s).to eq('10203')
      end
    end

    context 'with backward compatibility (default 2 digits)' do
      it 'maintains existing behavior when no digit parameters specified' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        formatter_old = described_class.new(prefix: '1')
        formatter_new = described_class.new(prefix: '1', major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)

        expect(formatter_old.build_code(version: version)).to eq(formatter_new.build_code(version: version))
      end
    end
  end

  describe 'digit count validation' do
    # Generate all combinations of [1,2,3] for each of the 4 digit count parameters
    all_digit_combinations = Array.new(4, [1, 2, 3]).reduce(&:product).map(&:flatten)

    context 'with valid digit counts' do
      it 'accepts digit counts from 1 to 3 individually' do
        (1..3).each do |count|
          # Test each parameter individually with safe defaults for others that stay within 8 digit limit
          expect { described_class.new(major_digits: count, minor_digits: 1, patch_digits: 1, build_digits: 1) }.not_to raise_error
          expect { described_class.new(major_digits: 1, minor_digits: count, patch_digits: 1, build_digits: 1) }.not_to raise_error
          expect { described_class.new(major_digits: 1, minor_digits: 1, patch_digits: count, build_digits: 1) }.not_to raise_error
          expect { described_class.new(major_digits: 1, minor_digits: 1, patch_digits: 1, build_digits: count) }.not_to raise_error
        end
      end

      context 'with mixed valid digit counts within 8 total digits' do
        all_digit_combinations.select { |combination| combination.sum <= 8 }.each do |major, minor, patch, build|
          it "accepts #{major},#{minor},#{patch},#{build} digit combination" do
            expect { described_class.new(major_digits: major, minor_digits: minor, patch_digits: patch, build_digits: build) }.not_to raise_error
          end
        end
      end
    end

    context 'with invalid digit counts' do
      it 'rejects digit counts outside valid range (1-3)' do
        expect { described_class.new(major_digits: 0) }.to raise_error(/Digit count must be between 1 and 3/)
        expect { described_class.new(minor_digits: -1) }.to raise_error(/Digit count must be between 1 and 3/)
        expect { described_class.new(patch_digits: 4) }.to raise_error(/Digit count must be between 1 and 3/)
      end

      it 'rejects non-integer digit counts' do
        expect { described_class.new(build_digits: '3') }.to raise_error(/Digit count must be an integer, got: String/)
        expect { described_class.new(major_digits: 2.5) }.to raise_error(/Digit count must be an integer, got: Float/)
        expect { described_class.new(minor_digits: 1.0) }.to raise_error(/Digit count must be an integer, got: Float/)
        expect { described_class.new(patch_digits: nil) }.to raise_error(/Digit count must be an integer, got: NilClass/)
      end

      context 'with configurations exceeding 8 total digits' do
        all_digit_combinations.select { |combination| combination.sum > 8 }.each do |major, minor, patch, build|
          it "rejects #{major},#{minor},#{patch},#{build} digit combination (total: #{major + minor + patch + build})" do
            expect { described_class.new(major_digits: major, minor_digits: minor, patch_digits: patch, build_digits: build) }.to raise_error(/Total digit count \(#{major + minor + patch + build}\) exceeds maximum allowed \(8\)/)
          end
        end
      end
    end
  end

  describe 'prefix validation' do
    context 'with valid prefixes' do
      it 'accepts single digits 0-9' do
        (0..9).each do |digit|
          expect { described_class.new(prefix: digit.to_s) }.not_to raise_error
        end
      end

      it 'accepts empty string' do
        expect { described_class.new(prefix: '') }.not_to raise_error
      end

      it 'accepts integer inputs' do
        expect { described_class.new(prefix: 5) }.not_to raise_error
      end

      it 'accepts nil prefix' do
        expect { described_class.new(prefix: nil) }.not_to raise_error
      end
    end

    context 'with invalid prefixes' do
      it 'rejects invalid prefix formats' do
        # Multi-character strings and out-of-range numbers
        expect { described_class.new(prefix: '12') }.to raise_error(/Prefix must be a single digit or empty string/)
        expect { described_class.new(prefix: '10') }.to raise_error(/Prefix must be a single digit or empty string/)
        expect { described_class.new(prefix: '-1') }.to raise_error(/Prefix must be a single digit or empty string/)

        # Non-numeric characters
        expect { described_class.new(prefix: 'a') }.to raise_error(/Prefix must be an integer digit/)
        expect { described_class.new(prefix: '@') }.to raise_error(/Prefix must be an integer digit/)
      end

      it 'rejects non-string and non-integer prefix types' do
        # Arrays, hashes, and other objects
        expect { described_class.new(prefix: []) }.to raise_error(/Prefix must be a string or integer/)
        expect { described_class.new(prefix: {}) }.to raise_error(/Prefix must be a string or integer/)
        expect { described_class.new(prefix: Object.new) }.to raise_error(/Prefix must be a string or integer/)
        expect { described_class.new(prefix: true) }.to raise_error(/Prefix must be a string or integer/)
        expect { described_class.new(prefix: false) }.to raise_error(/Prefix must be a string or integer/)
        expect { described_class.new(prefix: 3.14) }.to raise_error(/Prefix must be a string or integer/)
      end
    end
  end

  describe 'version component validation' do
    context 'with version components within digit limits' do
      it 'accepts version components that fit within their digit limits' do
        formatter = described_class.new(major_digits: 1, minor_digits: 2, patch_digits: 2, build_digits: 3)

        # Valid cases: major=9 (1 digit), minor=99 (2 digits), patch=99 (2 digits), build=999 (3 digits)
        version = Fastlane::Models::AppVersion.new(9, 99, 99, 999)
        expect { formatter.build_code(version: version) }.not_to raise_error
      end

      it 'accepts version components at exactly the digit limit' do
        formatter = described_class.new(major_digits: 2, minor_digits: 1, patch_digits: 3, build_digits: 2)

        # Edge cases: exactly at limits
        version = Fastlane::Models::AppVersion.new(99, 9, 999, 99)
        expect { formatter.build_code(version: version) }.not_to raise_error
      end
    end

    context 'with version components exceeding digit limits' do
      it 'rejects major version exceeding digit limit' do
        formatter = described_class.new(major_digits: 1, minor_digits: 2, patch_digits: 2, build_digits: 2)
        version = Fastlane::Models::AppVersion.new(10, 1, 1, 1) # major=10 is longer than 1 digit

        expect { formatter.build_code(version: version) }.to raise_error(
          /Version component value \(10\) exceeds maximum allowed width of 1 characters/
        )
      end

      it 'rejects minor version exceeding digit limit' do
        formatter = described_class.new(major_digits: 2, minor_digits: 1, patch_digits: 2, build_digits: 2)
        version = Fastlane::Models::AppVersion.new(1, 23, 4, 5) # minor=23 > max(9) for 1 digit

        expect { formatter.build_code(version: version) }.to raise_error(
          /Version component value \(23\) exceeds maximum allowed width of 1 characters/
        )
      end

      it 'rejects patch version exceeding digit limit' do
        formatter = described_class.new(major_digits: 2, minor_digits: 2, patch_digits: 1, build_digits: 2)
        version = Fastlane::Models::AppVersion.new(1, 2, 34, 5) # patch=34 > max(9) for 1 digit

        expect { formatter.build_code(version: version) }.to raise_error(
          /Version component value \(34\) exceeds maximum allowed width of 1 characters/
        )
      end

      it 'rejects build number exceeding digit limit' do
        formatter = described_class.new(major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 1)
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 46) # build_number=46 > max(9) for 1 digit

        expect { formatter.build_code(version: version) }.to raise_error(
          /Version component value \(46\) exceeds maximum allowed width of 1 characters/
        )
      end

      it 'provides helpful error messages with different digit limits' do
        formatter = described_class.new(major_digits: 2, minor_digits: 2, patch_digits: 2, build_digits: 2)
        version = Fastlane::Models::AppVersion.new(123, 4, 5, 6) # major=123 > max(99) for 2 digits

        expect { formatter.build_code(version: version) }.to raise_error(
          /Version component value \(123\) exceeds maximum allowed width of 2 characters.*Consider increasing the corresponding `\*_digits` parameter/
        )
      end

      it 'validates the first component that exceeds limits' do
        formatter = described_class.new(major_digits: 1, minor_digits: 1, patch_digits: 1, build_digits: 1)
        version = Fastlane::Models::AppVersion.new(12, 34, 56, 78) # All exceed 1 digit limit, but major is checked first

        expect { formatter.build_code(version: version) }.to raise_error(
          /Version component value \(12\) exceeds maximum allowed width of 1 characters/
        )
      end
    end
  end
end
