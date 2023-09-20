require 'spec_helper'
require 'java-properties'

describe Fastlane::Wpmreleasetoolkit::Versioning::AndroidVersionFile do
  describe 'read version name from version.properties' do
    it 'raises an error if version.properties is not present' do
      file_path = 'fake_path/test.xcconfig'

      expect { described_class.new(version_properties_path: file_path).read_version_name }
        .to raise_error(FastlaneCore::Interface::FastlaneError, "version.properties #{file_path} not found")
    end

    it 'raises an error if a version name is not present in version.properties' do
      expected_content = <<~CONTENT
        versionCode=123
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        expect { described_class.new(version_properties_path: tmp_file_path).read_version_name }
          .to raise_error(FastlaneCore::Interface::FastlaneError, 'Version name not found in version.properties')
      end
    end

    it 'reads a beta version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.new(version_properties_path: tmp_file_path).read_version_name
        expect(version_name.to_s).to eq('12.3.0.1')
      end
    end

    it 'reads a release version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.new(version_properties_path: tmp_file_path).read_version_name

        expect(version_name.to_s).to eq('12.3.0.0')
      end
    end

    it 'reads a patch/hotfix version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3.1
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.new(version_properties_path: tmp_file_path).read_version_name

        expect(version_name.to_s).to eq('12.3.1.0')
      end
    end

    it 'reads a patch/hotfix beta version number from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3.1-rc-2
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_name = described_class.new(version_properties_path: tmp_file_path).read_version_name

        expect(version_name.to_s).to eq('12.3.1.2')
      end
    end
  end

  describe 'read version code from version.properties' do
    it 'raises an error if version.properties is not present' do
      file_path = 'fake_path/test.xcconfig'

      expect { described_class.new(version_properties_path: file_path).read_version_code }
        .to raise_error(FastlaneCore::Interface::FastlaneError, "version.properties #{file_path} not found")
    end

    it 'raises an error if a version code is not present in version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3.1-rc-2
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        expect { described_class.new(version_properties_path: tmp_file_path).read_version_code }
          .to raise_error(FastlaneCore::Interface::FastlaneError, 'Version code not found in version.properties')
      end
    end

    it 'reads a version code from version.properties' do
      expected_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      with_tmp_file(named: 'version.properties', content: expected_content) do |tmp_file_path|
        version_code = described_class.new(version_properties_path: tmp_file_path).read_version_code

        expect(version_code.to_s).to eq('1240')
      end
    end
  end

  describe 'write version name to version.properties' do
    it 'raises an error if version.properties is not present' do
      file_path = 'fake_path/test.xcconfig'
      version_name = '1.2.3'
      version_code = '1234'

      expect { described_class.new(version_properties_path: file_path).write_version(version_name, version_code) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, "version.properties #{file_path} not found")
    end

    it 'writes the given release version name and version code to version.properties' do
      version_name = '1.2.3'
      version_code = '1240'

      existing_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      expected_content = <<~CONTENT
        versionName=#{version_name}
        versionCode=#{version_code}
      CONTENT

      with_tmp_file(named: 'version.properties', content: existing_content) do |tmp_file_path|
        described_class.new(version_properties_path: tmp_file_path).write_version(version_name, version_code)

        current_content = File.read(tmp_file_path)
        expect(current_content).to eq(expected_content.strip)
      end
    end

    it 'writes the given beta version name and version code to version.properties' do
      version_name = '1.2.3-rc-4'
      version_code = '1240'

      existing_content = <<~CONTENT
        versionName=12.3-rc-1
        versionCode=1240
      CONTENT

      expected_content = <<~CONTENT
        versionName=#{version_name}
        versionCode=#{version_code}
      CONTENT

      with_tmp_file(named: 'version.properties', content: existing_content) do |tmp_file_path|
        described_class.new(version_properties_path: tmp_file_path).write_version(version_name, version_code)

        current_content = File.read(tmp_file_path)
        expect(current_content).to eq(expected_content.strip)
      end
    end
  end
end
