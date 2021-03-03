require_relative '../../../spec_helper'

describe ReleaseToolkit::Models::Android::Version do
  it 'creates a new version from string name' do
    version = described_class.new(name: '1.2.3', code: 456)
    expect(version.name).to be_a(ReleaseToolkit::Models::Android::VersionName)
    expect(version.name.to_s).to eq('1.2.3')
  end

  it 'creates a new version from VersionName instance' do
    version = described_class.new(name: ReleaseToolkit::Models::Android::VersionName.from_string('1.2.3'), code: 456)
    expect(version.name).to be_a(ReleaseToolkit::Models::Android::VersionName)
    expect(version.name.to_s).to eq('1.2.3')
  end

  it 'creates a new version from string code' do
    version = described_class.new(name: '1.2.3', code: '456')
    expect(version.code).to be_a(Integer)
    expect(version.code).to eq(456)
  end

  it 'creates a new version from int code' do
    version = described_class.new(name: '1.2.3', code: 456)
    expect(version.code).to be_a(Integer)
    expect(version.code).to eq(456)
  end

  it 'accepts a nil code without crashing' do
    version = described_class.new(name: '1.2.3', code: nil)
    expect(version.code).to be_nil
  end

  it 'reads a single existing flavor from a gradle file' do
    version = described_class.from_gradle_file(path: fixture('wp'), flavor: :vanilla)
    expect(version.name.to_s).to eq('16.8-rc-1')
    expect(version.code).to eq(1003)
  end

  it 'returns nil when trying to read a flavor from a gradle file with no version info' do
    version = described_class.from_gradle_file(path: fixture('wc'), flavor: :vanilla)
    expect(version).to be_nil
  end

  private

  def fixture(name)
    File.join(__dir__, '..', '..', '..', 'test-data', 'version', "#{name}.gradle")
  end
end
