require 'spec_helper'

describe Fastlane::Locales do
  shared_examples 'from_xxx' do |key, fr_code, pt_code|
    let(:method_sym) { "from_#{key}".to_sym }

    it 'can find a locale from a single code' do
      fr_locale = described_class.send(method_sym, fr_code)
      expect(fr_locale).to be_instance_of(Fastlane::Locale)
      expect(fr_locale.glotpress).to eq('fr')
      expect(fr_locale.android).to eq('fr')
      expect(fr_locale.google_play).to eq('fr-FR')
    end

    it 'can find locales from a multiple codes' do
      locales = described_class.send(method_sym, [fr_code, pt_code])
      expect(locales).to be_instance_of(Array)

      expect(locales[0]).to be_instance_of(Fastlane::Locale)
      expect(locales[0].glotpress).to eq('fr')

      expect(locales[1]).to be_instance_of(Fastlane::Locale)
      expect(locales[1].glotpress).to eq('pt-br')
    end

    it 'raises if one of the locale codes passed was not found' do
      expect do
        described_class.send(method_sym, [fr_code, 'invalidcode', pt_code])
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

  describe 'from_ios' do
    include_examples 'from_xxx', :ios, 'fr-FR', 'pt-BR'
  end

  describe 'from_app_store' do
    include_examples 'from_xxx', :app_store, 'fr-FR', 'pt-BR'
  end

  describe 'subscript [] operator' do
    it 'returns an Array<Locale> even if a single one was passed' do
      locales = described_class['fr']
      expect(locales).to be_instance_of(Array)
      expect(locales.count).to equal(1)
      expect(locales[0].glotpress).to eq('fr')
    end

    it 'returns an Array<Locale> if a list of vararg codes was passed' do
      locales = described_class['fr', 'pt-br']
      expect(locales).to be_instance_of(Array)
      expect(locales.count).to equal(2)
      expect(locales[0]).to be_instance_of(Fastlane::Locale)
      expect(locales[0].glotpress).to eq('fr')
      expect(locales[1]).to be_instance_of(Fastlane::Locale)
      expect(locales[1].glotpress).to eq('pt-br')
    end

    it 'returns an Array<Locale> if an Array<String> of codes was passed' do
      list = %w[fr pt-br]
      locales = described_class[list]
      expect(locales).to be_instance_of(Array)
      expect(locales.count).to equal(2)
      expect(locales[0]).to be_instance_of(Fastlane::Locale)
      expect(locales[0].glotpress).to eq('fr')
      expect(locales[1]).to be_instance_of(Fastlane::Locale)
      expect(locales[1].glotpress).to eq('pt-br')
    end
  end

  it 'has only valid codes for known locales' do
    described_class.all.each do |locale|
      expect(locale.glotpress || 'xx').to match(/^[a-z]{2,3}(-[a-z]{2})?$/)
      expect(locale.android || 'xx-rYY').to match(/^[a-z]{2,3}(-r[A-Z]{2})?$/)
      expect(locale.google_play || 'xx-YY').to match(/^[a-z]{2,3}(-[A-Z]{2})?$/)
      expect(locale.app_store || 'xx-Yy').to match(/^[a-z]{2,3}(-[A-Za-z]{2,4})?$/)
      expect(locale.ios || 'xx-Yy').to match(/^[a-z]{2,3}(-[A-Za-z]{2,4})?$/)
    end
  end

  it 'returns exactly 16 Mag16 locales' do
    expect(described_class.mag16.count).to eq(16)
  end

  it 'is easy to do Locale subset intersections' do
    mag16_except_pt = described_class.mag16 - described_class['pt-br']
    expect(mag16_except_pt.count).to equal(15)
    expect(mag16_except_pt.find { |l| l.glotpress == 'pt-br' }).to be_nil
    expect(mag16_except_pt.find { |l| l.glotpress == 'fr' }).not_to be_nil
  end
end
