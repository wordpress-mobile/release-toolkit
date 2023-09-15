require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/helper/android/android_version_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/build_code'

describe Fastlane::Helper::Android::VersionHelper do
  describe 'get_version_from_properties' do
    it 'returns version name and code when present' do
      test_file_content = <<~CONTENT
        # Some header

        versionName=17.0
        versionCode=123

        alpha.versionName=alpha-222
        alpha.versionCode=1234
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with('./version.properties').and_return(test_file_content)
      expect(subject.get_version_from_properties).to eq('name' => '17.0', 'code' => 123)
    end

    it 'returns alpha version name and code when present' do
      test_file_content = <<~CONTENT
        # Some header

        versionName=17.0
        versionCode=123
        alpha.versionName=alpha-222
        alpha.versionCode=1234
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with('./version.properties').and_return(test_file_content)
      expect(subject.get_version_from_properties(is_alpha: true)).to eq('name' => 'alpha-222', 'code' => 1234)
    end

    it 'returns nil when alpha version name and code not present' do
      test_file_content = <<~CONTENT
        versionName=17.0
        versionCode=123
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with('./version.properties').and_return(test_file_content)
      expect(subject.get_version_from_properties(is_alpha: true)).to be_nil
    end
  end

  describe 'update_versions' do
    context 'with a version.properties file' do
      let(:original_content) do
        <<~CONTENT
          # Some header

          versionName=12.3
          versionCode=1234

          alpha.versionName=alpha-456
          alpha.versionCode=4567
        CONTENT
      end
      let(:new_beta_version) do
        { 'name' => '12.4-rc-1', 'code' => '1240' }
      end
      let(:new_alpha_version) do
        { 'name' => 'alpha-457', 'code' => '4570' }
      end

      it 'updates only the main version if no alpha provided' do
        expected_content = <<~CONTENT
          # Some header

          versionName=12.4-rc-1
          versionCode=1240

          alpha.versionName=alpha-456
          alpha.versionCode=4567
        CONTENT
        allow(File).to receive(:exist?).with('./version.properties').and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(original_content)
        expect(File).to receive(:write).with('./version.properties', expected_content)
        subject.update_versions(new_beta_version, nil)
      end

      it 'updates both the main and alpha versions if alpha provided' do
        expected_content = <<~CONTENT
          # Some header

          versionName=12.4-rc-1
          versionCode=1240

          alpha.versionName=alpha-457
          alpha.versionCode=4570
        CONTENT
        allow(File).to receive(:exist?).with('./version.properties').and_return(true)
        allow(File).to receive(:read).with('./version.properties').and_return(original_content)
        expect(File).to receive(:write).with('./version.properties', expected_content)
        subject.update_versions(new_beta_version, new_alpha_version)
      end
    end
  end

  describe 'get_library_version_from_gradle_config' do
    it 'returns nil when gradle file is not present' do
      allow(File).to receive(:exist?).and_return(false)
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to be_nil
    end

    it 'returns nil when the key is not present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key = 'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key-b')).to be_nil
      expect(subject.get_library_version_from_gradle_config(import_key: 'test-key')).to be_nil
    end

    it 'returns the key content when the key is present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key =  'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')

      # Make sure it handles double quotes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "bad"
        my-test-key = "my_test_value"
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')

      # Make sure it works with prefixes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "extbad"
        ext.my-test-key = 'my_test_value'
        ext..my_test_key_double = 'foo'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')
      expect(subject.get_library_version_from_gradle_config(import_key: 'my_test_key_double')).to be_nil

      # Make sure it works with spaces starting the line
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "extbad"
              ext.my-test-key = 'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with('./build.gradle', 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key')).to eq('my_test_value')
    end
  end

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
