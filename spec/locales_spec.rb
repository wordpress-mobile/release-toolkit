require 'spec_helper'

describe Fastlane::Locale do
  it 'returns a single Locale if one was found' do
    locale = Fastlane::Locale['fr']
    expect(locale).to be_instance_of(Fastlane::Locale)
    expect(locale.glotpress).to eq('fr')
  end

  it 'raises if no locale was found for a given code' do
    expect do
      Fastlane::Locale['invalidcode']
    end.to raise_error(RuntimeError, "Unknown locale for glotpress code 'invalidcode'")
  end
end

describe Fastlane::Locales do
  shared_examples 'from_xxx' do |key, fr_code, pt_code|
    let(:method_sym) { "from_#{key}".to_sym }
    it 'can find a locale from a single code' do
      fr_locale = Fastlane::Locales.send(method_sym, fr_code)
      expect(fr_locale).to be_instance_of(Fastlane::Locale)
      expect(fr_locale.glotpress).to eq('fr')
      expect(fr_locale.android).to eq('fr')
      expect(fr_locale.google_play).to eq('fr-FR')
    end

    it 'can find locales from a multiple codes' do
      locales = Fastlane::Locales.send(method_sym, [fr_code, pt_code])
      expect(locales).to be_instance_of(Array)

      expect(locales[0]).to be_instance_of(Fastlane::Locale)
      expect(locales[0].glotpress).to eq('fr')

      expect(locales[1]).to be_instance_of(Fastlane::Locale)
      expect(locales[1].glotpress).to eq('pt-br')
    end

    it 'raises if one of the locale codes passed was not found' do
      expect do
        Fastlane::Locales.send(method_sym, [fr_code, 'invalidcode', 'pt-br'])
      end.to raise_error(RuntimeError, "Unknown locale for #{key} code 'invalidcode'")
    end
  end

  describe 'from_glotpress' do
    include_examples 'from_xxx', :glotpress, 'fr', 'pt-br'
  end

  describe 'from_android' do
    include_examples 'from_xxx', :android, 'fr', 'pt-rBR'
  end

  describe 'from_google_play' do
    include_examples 'from_xxx', :google_play, 'fr-FR', 'pt-BR'
  end

  # @TODO: from_ios, from_app_store

  describe 'subscript [] operator' do
    it 'returns an Array<Locale> even if a single one was passed' do
      locales = Fastlane::Locales['fr']
      expect(locales).to be_instance_of(Array)
      expect(locales.count).to equal(1)
      expect(locales[0].glotpress).to eq('fr')
    end

    it 'returns an Array<Locale> if a list of vararg codes was passed' do
      locales = Fastlane::Locales['fr', 'pt-br']
      expect(locales).to be_instance_of(Array)
      expect(locales.count).to equal(2)
      expect(locales[0]).to be_instance_of(Fastlane::Locale)
      expect(locales[0].glotpress).to eq('fr')
      expect(locales[1]).to be_instance_of(Fastlane::Locale)
      expect(locales[1].glotpress).to eq('pt-br')
    end

    it 'returns an Array<Locale> if an Array<String> of codes was passed' do
      list = %w[fr pt-br]
      locales = Fastlane::Locales[list]
      expect(locales).to be_instance_of(Array)
      expect(locales.count).to equal(2)
      expect(locales[0]).to be_instance_of(Fastlane::Locale)
      expect(locales[0].glotpress).to eq('fr')
      expect(locales[1]).to be_instance_of(Fastlane::Locale)
      expect(locales[1].glotpress).to eq('pt-br')
    end
  end

  it 'returns exactly 16 Mag16 locales' do
    expect(Fastlane::Locales.mag16.count).to eq(16)
  end

  it 'is easy to do Locale subset intersections' do
    mag16_except_pt = Fastlane::Locales.mag16 - Fastlane::Locales['pt-br']
    expect(mag16_except_pt.count).to equal(15)
    expect(mag16_except_pt.find { |l| l.glotpress == 'pt-br' }).to be_nil
    expect(mag16_except_pt.find { |l| l.glotpress == 'fr' }).not_to be_nil
  end

  it 'can convert a Locale to a hash' do
    h = Fastlane::Locale['fr'].to_h
    expect(h).to eq({ glotpress: 'fr', android: 'fr', google_play: 'fr-FR', ios: nil, app_store: nil })
  end
end
