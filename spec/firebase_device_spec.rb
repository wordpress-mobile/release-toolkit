require 'spec_helper'

describe Fastlane::FirebaseDevice do
  let(:locale_sample_data) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-locale-list.json')) }
  let(:model_sample_data) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-model-list.json')) }
  let(:version_sample_data) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-version-list.json')) }

  before do |test|
    next if test.metadata[:calls_data_providers]

    allow(described_class).to receive(:locale_data).and_return(locale_sample_data)
    allow(described_class).to receive(:model_data).and_return(model_sample_data)
    allow(described_class).to receive(:version_data).and_return(version_sample_data)
  end

  def create_model(model: 'Nexus5', version: 27, locale: 'en', orientation: 'portrait')
    described_class.new(model: model, version: version, locale: locale, orientation: orientation)
  end

  describe 'initialization' do
    it 'assigns ivars correctly' do
      expect(create_model(model: 'Nexus5').model).to eq 'Nexus5'
      expect(create_model(version: 27).version).to eq 27
      expect(create_model(locale: 'en').locale).to eq 'en'
      expect(create_model(orientation: 'portrait').orientation).to eq 'portrait'
    end

    it 'throws for invalid model name' do
      expect { create_model(model: 'foo') }.to raise_exception('Invalid Model')
    end

    it 'throws for invalid version code' do
      expect { create_model(version: 99) }.to raise_exception('Invalid Version')
    end

    it 'throws for invalid locale code' do
      expect { create_model(locale: 'foo') }.to raise_exception('Invalid Locale')
    end
  end

  describe '#to_s' do
    subject { create_model.to_s }

    it { is_expected.to eq 'model=Nexus5,version=27,locale=en,orientation=portrait' }
  end

  describe '.valid_model_names' do
    subject { described_class.valid_model_names }

    it { is_expected.to be_an_instance_of(Array) }
    it { is_expected.to all(be_a(String)) }
  end

  describe '.valid_locales' do
    subject { described_class.valid_locales }

    it { is_expected.to be_an_instance_of(Array) }
    it { is_expected.to all(be_a(String)) }
  end

  describe '.valid_version_numbers' do
    subject { described_class.valid_version_numbers }

    it { is_expected.to be_an_instance_of(Array) }
    it { is_expected.to all(be_a(Integer)) }
  end

  describe '.valid_orientations' do
    subject { described_class.valid_orientations }

    it { is_expected.to be_an_instance_of(Array) }
    it { is_expected.to all(be_a(String)) }
    it { is_expected.to include 'portrait' }
    it { is_expected.to include 'landscape' }
  end

  describe '.locale_data' do
    it 'runs the right command', :calls_data_providers do
      allow(Fastlane::FirebaseAccount).to receive(:authenticated?).and_return(true)
      expect(Fastlane::Actions).to receive('sh').with('gcloud', 'firebase', 'test', 'android', 'locales', 'list', '--format="json"', log: false)
      described_class.locale_data
    end
  end

  describe '.model_data' do
    it 'runs the right command', :calls_data_providers do
      allow(Fastlane::FirebaseAccount).to receive(:authenticated?).and_return(true)
      expect(Fastlane::Actions).to receive('sh').with('gcloud', 'firebase', 'test', 'android', 'models', 'list', '--format="json"', log: false)
      described_class.model_data
    end
  end

  describe '.version_data' do
    it 'runs the right command', :calls_data_providers do
      allow(Fastlane::FirebaseAccount).to receive(:authenticated?).and_return(true)
      expect(Fastlane::Actions).to receive('sh').with('gcloud', 'firebase', 'test', 'android', 'versions', 'list', '--format="json"', log: false)
      described_class.version_data
    end
  end
end
