# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Helper::Ios::PluralRules do
  describe '.categories_for' do
    it 'maps single-form languages to [other]' do
      expect(described_class.categories_for('ja')).to eq(%i[other])
      expect(described_class.categories_for('zh')).to eq(%i[other])
    end

    it 'maps two-form languages to [one, other]' do
      expect(described_class.categories_for('en')).to eq(%i[one other])
      expect(described_class.categories_for('fr')).to eq(%i[one other])
    end

    it 'maps East-Slavic/Polish three-form languages to [one, few, many]' do
      expect(described_class.categories_for('ru')).to eq(%i[one few many])
      expect(described_class.categories_for('uk')).to eq(%i[one few many])
      expect(described_class.categories_for('pl')).to eq(%i[one few many])
    end

    it 'maps West-Slavic/Baltic/Romanian three-form languages to [one, few, other]' do
      expect(described_class.categories_for('cs')).to eq(%i[one few other])
      expect(described_class.categories_for('sk')).to eq(%i[one few other])
      expect(described_class.categories_for('ro')).to eq(%i[one few other])
    end

    it 'maps Slovenian to [one, two, few, other]' do
      expect(described_class.categories_for('sl')).to eq(%i[one two few other])
    end

    it 'maps Arabic to all six categories' do
      expect(described_class.categories_for('ar')).to eq(%i[zero one two few many other])
    end

    it 'maps GlotPress 2-form locales to [one, other], following GlotPress rather than CLDR' do
      # GlotPress keeps Hebrew at two forms though CLDR has three (one/two/other),
      # and Indonesian at two though CLDR has one. The `.po` we consume has two
      # forms, so we map two — accepting the missing Hebrew dual.
      expect(described_class.categories_for('he')).to eq(%i[one other])
      expect(described_class.categories_for('is')).to eq(%i[one other])
      expect(described_class.categories_for('id')).to eq(%i[one other])
    end

    it 'maps Croatian/Serbian/Bosnian to [one, few, other]' do
      # Same gettext formula as Russian, but CLDR names the third form `other`, not `many`.
      expect(described_class.categories_for('hr')).to eq(%i[one few other])
      expect(described_class.categories_for('sr')).to eq(%i[one few other])
      expect(described_class.categories_for('bs')).to eq(%i[one few other])
    end

    it 'raises a specific error for GlotPress/CLDR-incompatible locales (Welsh)' do
      expect { described_class.categories_for('cy') }
        .to raise_error(described_class::UnknownLocaleError, /legacy 4-form Welsh/)
    end

    it 'falls back from a regional code to its base language' do
      expect(described_class.categories_for('pt-BR')).to eq(%i[one other])
      expect(described_class.categories_for('pt-PT')).to eq(%i[one other])
      expect(described_class.categories_for('zh-Hans')).to eq(%i[other])
    end

    it 'normalizes case and underscores' do
      expect(described_class.categories_for('RU')).to eq(%i[one few many])
      expect(described_class.categories_for('ru_RU')).to eq(%i[one few many])
    end

    it 'raises a clear error for an unmapped locale' do
      expect { described_class.categories_for('xx') }
        .to raise_error(described_class::UnknownLocaleError, /No plural-category mapping for locale 'xx'/)
    end
  end

  describe '.supported?' do
    it 'is true for mapped locales and their regional variants' do
      expect(described_class.supported?('ru')).to be true
      expect(described_class.supported?('pt-BR')).to be true
    end

    it 'is false for unmapped locales' do
      expect(described_class.supported?('xx')).to be false
    end

    it 'is false for known GlotPress/CLDR-incompatible locales (Welsh)' do
      expect(described_class.supported?('cy')).to be false
    end
  end
end
