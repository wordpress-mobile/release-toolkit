require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::IOSVersionFile do
  describe 'write the provided version numbers to an xcconfig file' do
    context 'when the .xcconfig file exists' do
      it 'writes the versions to the .xcconfig file' do
        version_short = '4.5.6'
        version_long = '5.6.7.8'
        build_number = '1234'

        existing_content = <<~CONTENT
          BUILD_NUMBER = 5678
          VERSION_LONG = 1.2.3.4
          VERSION_SHORT = 1.2.3
        CONTENT

        expected_content = <<~CONTENT
          BUILD_NUMBER = #{build_number}
          VERSION_LONG = #{version_long}
          VERSION_SHORT = #{version_short}
        CONTENT

        with_tmp_file(named: 'test.xcconfig', content: existing_content) do |tmp_file_path|
          described_class.new(xcconfig_path: tmp_file_path).write(
            version_short:,
            version_long:,
            build_number:
          )

          current_content = File.read(tmp_file_path)
          expect(current_content).to eq(expected_content)
        end
      end
    end

    context 'when the .xcconfig file does not exist' do
      file_path = 'fake_path/test.xcconfig'
      version_short = '1.2.3'

      it 'raises an error' do
        expect { described_class.new(xcconfig_path: file_path).write(version_short:) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, ".xcconfig file not found at this path: #{file_path}")
      end
    end
  end

  describe 'read the build code from the provided .xcconfig file' do
    context 'when the .xcconfig file does not exist' do
      it 'raises an error' do
        file_path = 'fake_path/test.xcconfig'

        expect { described_class.new(xcconfig_path: file_path).read_build_code }
          .to raise_error(FastlaneCore::Interface::FastlaneError, ".xcconfig file not found at this path: #{file_path}")
      end
    end

    context 'when an incorrect `attribute_name` is passed' do
      it 'raises an error' do
        file_content = <<~CONTENT
          VERSION_LONG = 1.2.3.4
          VERSION_SHORT = 1.2.3
          BUILD_NUMBER = 5678
        CONTENT

        with_tmp_file(named: 'test.xcconfig', content: file_content) do |tmp_file_path|
          expect { described_class.new(xcconfig_path: tmp_file_path).read_build_code(attribute_name: 'WRONG_ATTRIBUTE_NAME') }
            .to raise_error(FastlaneCore::Interface::FastlaneError, 'attribute_name must be `VERSION_LONG` or `BUILD_NUMBER`')
        end
      end
    end

    context 'when the .xcconfig file exists' do
      context 'when the build code is stored in the VERSION_LONG attribute' do
        it 'reads the build code from the .xcconfig file' do
          file_content = <<~CONTENT
            VERSION_LONG = 1.2.3.4
            VERSION_SHORT = 1.2.3
            BUILD_NUMBER = 5678
          CONTENT

          with_tmp_file(named: 'test.xcconfig', content: file_content) do |tmp_file_path|
            build_code = described_class.new(xcconfig_path: tmp_file_path).read_build_code(attribute_name: 'VERSION_LONG')

            expect(build_code.to_s).to eq('1.2.3.4')
          end
        end
      end

      context 'when the build code is stored in the BUILD_NUMBER attribute' do
        it 'reads the build code from the .xcconfig file' do
          file_content = <<~CONTENT
            VERSION_LONG = 1.2.3.4
            VERSION_SHORT = 1.2.3
            BUILD_NUMBER = 5678
          CONTENT

          with_tmp_file(named: 'test.xcconfig', content: file_content) do |tmp_file_path|
            build_code = described_class.new(xcconfig_path: tmp_file_path).read_build_code(attribute_name: 'BUILD_NUMBER')

            expect(build_code.to_s).to eq('5678')
          end
        end
      end
    end
  end

  describe 'read the release version number from the provided .xcconfig file' do
    context 'when the .xcconfig file exists' do
      it 'reads the version number from the .xcconfig file' do
        file_content = <<~CONTENT
          VERSION_LONG = 1.2.3.4
          VERSION_SHORT = 1.2.3
          BUILD_NUMBER = 5678
        CONTENT

        with_tmp_file(named: 'test.xcconfig', content: file_content) do |tmp_file_path|
          version = described_class.new(xcconfig_path: tmp_file_path).read_release_version

          expect(version.to_s).to eq('1.2.3')
        end
      end
    end

    context 'when the .xcconfig file does not exist' do
      it 'raises an error' do
        file_path = 'fake_path/test.xcconfig'

        expect { described_class.new(xcconfig_path: file_path).read_release_version }
          .to raise_error(FastlaneCore::Interface::FastlaneError, ".xcconfig file not found at this path: #{file_path}")
      end
    end
  end
end
