require 'spec_helper'

describe Fastlane::Helper::Android::VersionHelper do
  before do
    stub_const('BUILD_GRADLE_PATH', './build.gradle')
    stub_const('VERSION_PROPERTIES_PATH', './version.properties')
  end

  shared_examples 'robustly accepts version.properties and build.gradle paths' do |method|
    it 'returns the value from version.properties over build.gradle when both are given' do
      test_build_gradle_content = <<~CONTENT
        android {
          defaultConfig {
            versionName "2.31"
            versionCode 164
          }
        }
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      # The method delegates to get_version_from_properties.
      # Stubbing it binds the two implemenations, but it's convenient in the context of these shared examples.
      # Notice that get_version_from_properties is well tested.
      allow(described_class).to receive(:get_version_from_properties).and_return({ name: '17.0', code: 123 })
      allow(File).to receive(:read).with(BUILD_GRADLE_PATH).and_return(test_build_gradle_content)

      expect(subject.send(method, version_properties_path: VERSION_PROPERTIES_PATH, build_gradle_path: BUILD_GRADLE_PATH)).to eq(name: '17.0', code: 123)
    end

    it 'returns the value from version.properties over build.gradle when the latter is nil' do
      allow(File).to receive(:exist?).and_return(true)
      # The method delegates to get_version_from_properties.
      # Stubbing it binds the two implemenations, but it's convenient in the context of these shared examples.
      # Notice that get_version_from_properties is well tested.
      allow(described_class).to receive(:get_version_from_properties).and_return({ name: '17.0', code: 123 })

      expect(subject.send(method, version_properties_path: VERSION_PROPERTIES_PATH, build_gradle_path: nil)).to eq(name: '17.0', code: 123)
    end

    it 'returns the value from build.gradle when version.properties is nil' do
      in_tmp_dir do |tmp_dir|
        # The implementation opens the file and iterates on each_lines.
        # It's therefore easier to create the file rather than stubbing it at runtime.
        build_gradle_path = File.join(tmp_dir, BUILD_GRADLE_PATH)
        File.write(
          build_gradle_path,
          <<~CONTENT
            android {
              defaultConfig {
                versionName "2.31"
                versionCode 164
              }
            }
          CONTENT
        )

        expect(subject.send(method, version_properties_path: nil, build_gradle_path: BUILD_GRADLE_PATH)).to eq('name' => '2.31', 'code' => 164)
      end
    end

    it 'fails when both version.properties and build.gradle are nil' do
      expect { subject.send(method, version_properties_path: nil, build_gradle_path: nil) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, 'Both version.properties and build.gradle paths where either nil or invalid.')
    end
  end

  describe 'get_release_version' do
    include_examples 'robustly accepts version.properties and build.gradle paths', :get_release_version
  end

  describe 'get_alpha_version' do
    include_examples 'robustly accepts version.properties and build.gradle paths', :get_alpha_version
  end

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
      allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(test_file_content)
      expect(subject.get_version_from_properties(version_properties_path: VERSION_PROPERTIES_PATH)).to eq('name' => '17.0', 'code' => 123)
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
      allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(test_file_content)
      expect(subject.get_version_from_properties(version_properties_path: VERSION_PROPERTIES_PATH, is_alpha: true)).to eq('name' => 'alpha-222', 'code' => 1234)
    end

    it 'returns nil when alpha version name and code not present' do
      test_file_content = <<~CONTENT
        versionName=17.0
        versionCode=123
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(test_file_content)
      expect(subject.get_version_from_properties(version_properties_path: VERSION_PROPERTIES_PATH, is_alpha: true)).to be_nil
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
        allow(File).to receive(:exist?).with(VERSION_PROPERTIES_PATH).and_return(true)
        allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(original_content)
        expect(File).to receive(:write).with(VERSION_PROPERTIES_PATH, expected_content)
        subject.update_versions(new_beta_version, nil, build_gradle_path: nil, version_properties_path: VERSION_PROPERTIES_PATH)
      end

      it 'updates both the main and alpha versions if alpha provided' do
        expected_content = <<~CONTENT
          # Some header

          versionName=12.4-rc-1
          versionCode=1240

          alpha.versionName=alpha-457
          alpha.versionCode=4570
        CONTENT
        allow(File).to receive(:exist?).with(VERSION_PROPERTIES_PATH).and_return(true)
        allow(File).to receive(:read).with(VERSION_PROPERTIES_PATH).and_return(original_content)
        expect(File).to receive(:write).with(VERSION_PROPERTIES_PATH, expected_content)
        subject.update_versions(new_beta_version, new_alpha_version, build_gradle_path: nil, version_properties_path: VERSION_PROPERTIES_PATH)
      end
    end
  end

  describe 'get_library_version_from_gradle_config' do
    it 'returns nil when gradle file is not present' do
      allow(File).to receive(:exist?).and_return(false)
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil
    end

    it 'returns nil when the key is not present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key = 'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key-b', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil
      expect(subject.get_library_version_from_gradle_config(import_key: 'test-key', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil
    end

    it 'returns the key content when the key is present' do
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = 'bad'
        my-test-key =  'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')

      # Make sure it handles double quotes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "bad"
        my-test-key = "my_test_value"
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')

      # Make sure it works with prefixes
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "extbad"
        ext.my-test-key = 'my_test_value'
        ext..my_test_key_double = 'foo'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')
      expect(subject.get_library_version_from_gradle_config(import_key: 'my_test_key_double', build_gradle_path: BUILD_GRADLE_PATH)).to be_nil

      # Make sure it works with spaces starting the line
      test_file_content = <<~CONTENT
        my-test-key-foo = 'foo'
        my-test-key-bad = "extbad"
              ext.my-test-key = 'my_test_value'
      CONTENT

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).with(BUILD_GRADLE_PATH, 'r').and_yield(StringIO.new(test_file_content))
      expect(subject.get_library_version_from_gradle_config(import_key: 'my-test-key', build_gradle_path: BUILD_GRADLE_PATH)).to eq('my_test_value')
    end
  end
end
