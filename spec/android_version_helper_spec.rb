require 'spec_helper'

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
      expect(subject.get_version_from_properties()).to eq('name' => '17.0', 'code' => 123)
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

  describe 'calculates_the_next_release_base_version' do
    context 'when using calendar_versioning' do
      it 'increments the minor version number' do
        version = {
          'name' => '1995.5-rc-3',
          'code' => '100'
        }
        next_version = described_class.calc_next_release_base_version(version, 'calendar_versioning')
        expect(next_version['name']).to eq('1995.6')
      end

      it 'increments the major version number and resets the minor version number to 1 if it is the first release of the next year' do
        allow(Time).to receive(:now).and_return(Time.new(2023, 12, 3))
        allow(FastlaneCore::UI).to receive(:confirm).and_return(true)
        version = {
          'name' => '1995.26-rc-3',
          'code' => '100'
        }
        next_version = described_class.calc_next_release_base_version(version, 'calendar_versioning')
        expect(next_version['name']).to eq('1996.1')
      end

      it 'does not increment the major version number if it is not the first release of the next year' do
        allow(Time).to receive(:now).and_return(Time.new(2023, 12, 1))
        allow(FastlaneCore::UI).to receive(:confirm).and_return(false)
        version = {
          'name' => '1995.26-rc-1',
          'code' => '100'
        }
        next_version = described_class.calc_next_release_base_version(version, 'calendar_versioning')
        expect(next_version['name']).to eq('1995.27')
      end
    end

    context 'when using marketing_versioning if the minor version number is 9 or less' do
      it 'increments the minor version number' do
        version = {
          'name' => '1.0-rc-3',
          'code' => '100'
        }
        next_version = described_class.calc_next_release_base_version(version, 'marketing_versioning')
        expect(next_version['name']).to eq('1.1')
      end

      it 'resets the minor version number to 0 and increments the major version number if the minor number is 9' do
        version = {
          'name' => '1.9-rc-3',
          'code' => '100'
        }
        next_version = described_class.calc_next_release_base_version(version, 'marketing_versioning')
        expect(next_version['name']).to eq('2.0')
      end

      it 'does not reset the minor version number if it is less than 10' do
        version = {
          'name' => '1.5-rc-4',
          'code' => '100'
        }
        next_version = described_class.calc_next_release_base_version(version, 'marketing_versioning')
        expect(next_version['name']).to eq('1.6')
      end
    end

    context 'when an invalid versioning scheme is provided' do
      it 'raises an error' do
        version = {
          'name' => '1.0-rc-3',
          'code' => '100'
        }
        error_message = "Please set the versioning scheme to 'calendar_versioning' or 'marketing_versioning'"
        expect do
          described_class.calc_next_release_base_version(version, 'invalid_scheme')
        end.to raise_error(FastlaneCore::Interface::FastlaneError, error_message)
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
end
