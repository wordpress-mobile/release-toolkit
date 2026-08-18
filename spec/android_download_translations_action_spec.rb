# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::AndroidDownloadTranslationsAction do
  it 'passes fail_on_error to the download helper' do
    allow(Fastlane::Helper::Android::LocalizeHelper).to receive(:create_available_languages_file)
    expect(Fastlane::Helper::Android::LocalizeHelper).to receive(:download_from_glotpress).with(hash_including(fail_on_error: true))

    run_described_fastlane_action(
      res_dir: 'res',
      glotpress_url: 'https://translate.example/projects/test/',
      status_filter: ['current'],
      source_locale: 'en_US',
      locales: [{ glotpress: 'fr', android: 'fr' }],
      lint_task: nil,
      skip_commit: true,
      fail_on_error: true
    )
  end

  it 'keeps fail_on_error disabled by default' do
    option = described_class.available_options.find { |item| item.key == :fail_on_error }

    expect(option.default_value).to be(false)
  end
end
