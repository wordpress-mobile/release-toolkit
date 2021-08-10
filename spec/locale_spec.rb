require 'spec_helper'

describe Fastlane::Locale do
  it 'returns a single Locale if one was found' do
    locale = described_class['fr']
    expect(locale).to be_instance_of(described_class)
    expect(locale.glotpress).to eq('fr')
  end

  it 'raises if no locale was found for a given code' do
    expect do
      described_class['invalidcode']
    end.to raise_error(RuntimeError, "Unknown locale for glotpress code 'invalidcode'")
  end

  it 'can convert a Locale to a hash' do
    h = described_class['fr'].to_h
    expect(h).to eq({ glotpress: 'fr', android: 'fr', google_play: 'fr-FR', ios: 'fr-FR', app_store: 'fr-FR' })
  end
end
