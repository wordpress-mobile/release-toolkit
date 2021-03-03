require_relative '../../../spec_helper'

describe ReleaseToolkit::Models::Android::VersionSet do
  context 'when parsing a build.gradle file' do
    it 'handles defaultConfig and vanilla' do
      using_gradle_fixture('wp') do |gradle_file_path|
        flavors = [:defaultConfig, :vanilla]
        version_set = described_class.from_gradle_file(path: gradle_file_path, flavors: flavors)
        expect(version_set.flavors.keys).to eq(flavors)
        expect(version_set[:defaultConfig].name.to_s).to eq('alpha-278')
        expect(version_set[:defaultConfig].code).to eq(1004)
        expect(version_set[:vanilla].name.to_s).to eq('16.8-rc-1')
        expect(version_set[:vanilla].code).to eq(1003)
      end
    end

    it 'handles missing flavor' do
      using_gradle_fixture('wc') do |gradle_file_path|
        flavors = [:defaultConfig, :vanilla]
        version_set = described_class.from_gradle_file(path: gradle_file_path, flavors: flavors)
        expect(version_set.flavors.keys).to eq([:defaultConfig])
        expect(version_set[:defaultConfig].name.to_s).to eq('6.1-rc-2')
        expect(version_set[:defaultConfig].code).to eq(201)
      end
    end
  end

  context 'when updating a build.gradle file' do
    it 'updates the defaultConfig name and code correctly' do
      using_gradle_fixture('wp') do |gradle_file_path|
        version_set = described_class.new(
          defaultConfig: ReleaseToolkit::Models::Android::Version.new(name: 'alpha-300', code: 1011)
        )
        version_set.apply_to_gradle_file(path: gradle_file_path)
        expect_content(of_file: gradle_file_path, to_match_fixture: 'wp-defaultConfig-updated')
      end
    end

    it 'updates the vanilla name and code correctly' do
      using_gradle_fixture('wp') do |gradle_file_path|
        version_set = described_class.new(
          vanilla: ReleaseToolkit::Models::Android::Version.new(name: '16.8-rc-3', code: 1010)
        )
        version_set.apply_to_gradle_file(path: gradle_file_path)
        expect_content(of_file: gradle_file_path, to_match_fixture: 'wp-vanilla-updated')
      end
    end

    it 'does not update any version-less flavor' do
      using_gradle_fixture('wp') do |gradle_file_path|
        version_set = described_class.new(
          wasabi: ReleaseToolkit::Models::Android::Version.new(name: 'alpha-123', code: 1234)
        )
        version_set.apply_to_gradle_file(path: gradle_file_path)
        expect_content(of_file: gradle_file_path, to_match_fixture: 'wp')
      end
    end

    it 'knows how to update multiple flavors at once' do
      using_gradle_fixture('wp') do |gradle_file_path|
        version_set = described_class.new(
          defaultConfig: ReleaseToolkit::Models::Android::Version.new(name: 'alpha-321', code: 1011),
          vanilla: ReleaseToolkit::Models::Android::Version.new(name: '16.9-rc-3', code: 1010)
        )
        version_set.apply_to_gradle_file(path: gradle_file_path)
        expect_content(of_file: gradle_file_path, to_match_fixture: 'wp-allFlavors-updated')
      end
    end

    it 'update only the known flavors' do
      using_gradle_fixture('wc') do |gradle_file_path|
        version_set = described_class.new(
          defaultConfig: ReleaseToolkit::Models::Android::Version.new(name: '6.3-rc-1', code: 234),
          vanilla: ReleaseToolkit::Models::Android::Version.new(name: '18.2.4', code: 238)
        )
        version_set.apply_to_gradle_file(path: gradle_file_path)
        expect_content(of_file: gradle_file_path, to_match_fixture: 'wc-defaultConfig-updated')
      end
    end
  end

  ###############

  private

  # @param [String] name basename of the fixture file inside 'test-data/version/{name}.gradle' to use
  # @yield [String] The path to the temp file where this fixture has been copied to run the test on it.
  def using_gradle_fixture(name)
    Dir.mktmpdir('a8c-android-version-tests-') do |dir|
      fixture = fixture_path(name)
      dest = File.join(dir, 'build.gradle')
      FileUtils.cp(fixture, dest)
      yield dest
      FileUtils.rm(dest)
    end
  end

  def fixture_path(name)
    File.join(__dir__, '..', '..', '..', 'test-data', 'version', "#{name}.gradle")
  end

  def expect_content(of_file:, to_match_fixture:)
    file_content = File.read(of_file)
    fixture_content = File.read(fixture_path(to_match_fixture))
    expect(file_content).to eq(fixture_content)
  end
end
