require 'spec_helper'

def create_model(model: 'Nexus5', version: 2, locale: 'en', orientation: 'portrait')
  Fastlane::Helper::Android::FirebaseHelper::FirebaseDevice.new(
    model: model,
    version: version,
    locale: locale,
    orientation: orientation
  )
end

describe Fastlane::Helper::Android::FirebaseHelper::FirebaseDevice do
  before do
    allow(described_class).to receive(:valid_model_names).and_return(['Nexus5'])
    allow(described_class).to receive(:valid_version_numbers).and_return([1, 2, 3])
    allow(described_class).to receive(:valid_locales).and_return(['en'])
  end

  describe 'initialization' do
    it 'assigns ivars correctly' do
      expect(create_model(model: 'Nexus5').model).to eq 'Nexus5'
      expect(create_model(version: 3).version).to eq 3
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

  describe 'to_s' do
    it 'contains the specified elements' do
      expect(create_model.to_s).to eq 'model=Nexus5,version=2,locale=en,orientation=portrait'
    end
  end
end
