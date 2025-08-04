# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::DerivedBuildCodeFormatter do
  describe 'derives a build code from an AppVersion object' do
    context 'with default prefix (backward compatibility)' do
      it 'derives the build code from version numbers that are single digits' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        build_code_string = described_class.new.build_code(version: version)
        expect(build_code_string.to_s).to eq('101020304')
      end

      it 'derives the build code from version numbers that are two digits' do
        version = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
        build_code_string = described_class.new.build_code(version: version)
        expect(build_code_string.to_s).to eq('112345678')
      end
    end

    context 'with explicit prefix' do
      it 'derives the build code with prefix "1"' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        formatter = described_class.new(prefix: '1')
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('101020304')
      end

      it 'derives the build code with prefix "2"' do
        version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
        formatter = described_class.new(prefix: '2')
        build_code_string = formatter.build_code(version: version)
        expect(build_code_string.to_s).to eq('201020304')
      end

      it 'derives the build code with prefix "0"' do
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
    end

    context 'with invalid prefixes' do
      it 'rejects multi-character strings' do
        expect { described_class.new(prefix: '12') }.to raise_error(/Prefix must be a single digit or empty string/)
      end

      it 'rejects non-numeric strings' do
        expect { described_class.new(prefix: 'a') }.to raise_error(/Prefix must be an integer digit/)
      end

      it 'rejects numbers outside 0-9 range' do
        expect { described_class.new(prefix: '10') }.to raise_error(/Prefix must be a single digit or empty string/)
        expect { described_class.new(prefix: '-1') }.to raise_error(/Prefix must be a single digit or empty string/)
      end

      it 'rejects symbols and special characters' do
        expect { described_class.new(prefix: '@') }.to raise_error(/Prefix must be an integer digit/)
        expect { described_class.new(prefix: '#') }.to raise_error(/Prefix must be an integer digit/)
      end
    end
  end
end
