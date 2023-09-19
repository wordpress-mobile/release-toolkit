require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/helper/android/android_version_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/build_code'

describe Fastlane::Wpmreleasetoolkit::Versioning::AndroidVersionFile do
  describe 'read version name from version.properties' do
    it 'raises an error if version.properties is not present' do
      file_path = 'fake_path/test.xcconfig'

      expect { described_class.read_version_name_from_version_properties(file_path) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, "version.properties #{file_path} not found")
    end

    it 'raises an error if a version name is not present in version.properties' do
      expected_content = <<~CONTENT
        versionCode=123
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        expect { described_class.read_version_name_from_version_properties(tmp_file_path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, 'Version name not found in version.properties')
      end
    end

    it 'reads a beta version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.read_version_name_from_version_properties(tmp_file_path)

        expect(version_name.to_s).to eq('12.3.0.1')
      end
    end

    it 'reads a release version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.read_version_name_from_version_properties(tmp_file_path)

        expect(version_name.to_s).to eq('12.3.0.0')
      end
    end

    it 'reads a patch/hotfix version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3.1
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.read_version_name_from_version_properties(tmp_file_path)

        expect(version_name.to_s).to eq('12.3.1.0')
      end
    end

    it 'reads a patch/hotfix beta version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3.1-rc-2
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.read_version_name_from_version_properties(tmp_file_path)

        expect(version_name.to_s).to eq('12.3.1.2')
      end
    end
  end

  describe 'read version code from version.properties' do
    it 'raises an error if version.properties is not present' do
      file_path = 'fake_path/test.xcconfig'

      expect { described_class.read_version_code_from_version_properties(file_path) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, "version.properties #{file_path} not found")
    end

    it 'raises an error if a version code is not present in version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3.1-rc-2
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        expect { described_class.read_version_code_from_version_properties(tmp_file_path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, 'Version code not found in version.properties')
      end
    end

    it 'reads a version code from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.read_version_code_from_version_properties(tmp_file_path)

        expect(version_name.to_s).to eq('1240')
      end
    end
  end

  describe 'write version name to version.properties' do
    it 'raises an error if version.properties is not present' do
      file_path = 'fake_path/test.xcconfig'
      version_name = '1.2.3'

      expect { described_class.write_version_name_to_version_properties(file_path, version_name) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, "version.properties #{file_path} not found")
    end

    it 'writes the given release version name to version.properties' do
      version_name = '1.2.3'

      existing_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      expected_content = <<~CONTENT
        versionName=1.2.3
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: existing_content) do |tmp_file_path|
        described_class.write_version_name_to_version_properties(tmp_file_path, version_name)

        current_content = File.read(tmp_file_path)
        expect(current_content).to eq(expected_content)
      end
    end

    it 'writes the given beta version name to version.properties' do
      version_name = '1.2.3-rc-4'

      existing_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      expected_content = <<~CONTENT
        versionName=1.2.3-rc-4
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: existing_content) do |tmp_file_path|
        described_class.write_version_name_to_version_properties(tmp_file_path, version_name)

        current_content = File.read(tmp_file_path)
        expect(current_content).to eq(expected_content)
      end
    end

    it 'writes the given version code to version.properties' do
      version_code = '1234'

      existing_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      expected_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1234
      CONTENT

      with_tmp_file(named: 'version.properties', content: existing_content) do |tmp_file_path|
        described_class.write_version_code_to_version_properties(tmp_file_path, version_code)

        current_content = File.read(tmp_file_path)
        expect(current_content).to eq(expected_content)
      end
    end
  end
end
