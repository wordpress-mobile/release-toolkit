require_relative './spec_helper'

describe Fastlane::Helper::AndroidLocalizeHelper do
  context "get_glotpress_languages_translated_morethan90 can" do
    it 'find all languages at completion threshold' do
      languages_at_threshold = ["es-ve", "ru", "ko", "zh-cn"]
      test_text = File.open("spec/test-data/localize/threshold_all.txt")
      languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text)

      # verify function return value
      expect(languages_at_threshold.sort).to eq languages_found.sort
    end

    it 'find only languages at completion threshold' do
      languages_at_threshold = ["es-ve", "ru"]
      test_text = File.open("spec/test-data/localize/threshold_some.txt")

      languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text)

      # verify function return value
      expect(languages_at_threshold.sort).to eq languages_found.sort
    end

    it 'find no languages when none is at threshold' do
      test_text = File.open("spec/test-data/localize/threshold_none.txt")

      languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text)

      # verify function return value
      expect(languages_found.empty?).to be true
    end

    it 'return empty result when input is irrelevant html' do
      test_text = File.open("spec/test-data/localize/random_html.txt")

      languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text)

      # verify function return value
      expect(languages_found.empty?).to be true
    end

    it 'return empty result when input is random text' do
      test_text = File.open("spec/test-data/localize/random_text.txt")
      languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text)

      # verify function return value
      expect(languages_found.empty?).to be true
    end

    it 'return empty result when input is empty string' do
      test_text = File.open("spec/test-data/localize/empty.txt")
      languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text)

      # verify function return value
      expect(languages_found.empty?).to be true
    end
  end

  context "get_missing_languages can" do
    it 'return empty result when no languages are missing from language file' do
      languages_to_check = ["en-us", "az", "es-cl", "zh-cn", "kmr"]
      test_file = "spec/test-data/csv/language-codes.csv"
      missing_languages = Fastlane::Helper::AndroidLocalizeHelper.get_missing_languages(languages_to_check, test_file, false)

      # verify function return value
      expect(missing_languages.empty?).to be true
    end

    it 'find missing languages when all are missing from language file' do
      languages_to_check_missing = ["en-ca", "pt-br", "ru", "hi", "pl"]
      test_file = "spec/test-data/csv/language-codes.csv"
      missing_languages = Fastlane::Helper::AndroidLocalizeHelper.get_missing_languages(languages_to_check_missing, test_file, false)

      # verify function return value
      expect(missing_languages.sort).to eq languages_to_check_missing.sort
    end

    it 'find missing languages when not all are missing from language file' do
      languages_to_check_missing = ["en-ca", "pt-br", "ru", "hi", "pl"]
      languages_to_check_not_missing = ["en-us", "az", "es-cl", "zh-cn", "kmr"]
      languages_to_check = languages_to_check_missing + languages_to_check_not_missing;
      test_file = "spec/test-data/csv/language-codes.csv"
      missing_languages = Fastlane::Helper::AndroidLocalizeHelper.get_missing_languages(languages_to_check, test_file, false)

      # verify function return value
      expect(missing_languages.sort).to eq languages_to_check_missing.sort
    end

    it 'return all missing languages when language file is empty' do
      languages_to_check = ["en-us", "az", "es-cl", "zh-cn", "kmr"]
      test_file = "spec/test-data/empty.csv"
      missing_languages = Fastlane::Helper::AndroidLocalizeHelper.get_missing_languages(languages_to_check, test_file, false)

      # verify function return value
      expect(missing_languages.sort).to eq languages_to_check.sort
    end

    it 'return all missing languages when language file is malformed' do
      languages_to_check = ["en-us", "az", "es-cl", "zh-cn", "kmr"]
      test_file = "spec/test-data/malformed.csv"
      missing_languages = Fastlane::Helper::AndroidLocalizeHelper.get_missing_languages(languages_to_check, test_file, false)

      # verify function return value
      expect(missing_languages.sort).to eq languages_to_check.sort
    end
  end
end
