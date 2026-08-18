# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::GpDownloadmetadataAction do
  it 'passes fail_on_error to the metadata downloader' do
    in_tmp_dir do |tmpdir|
      expect(Fastlane::Helper::MetadataDownloader).to receive(:new).with(tmpdir, {}, false, fail_on_error: true)

      run_described_fastlane_action(
        project_url: 'https://translate.example/projects/test/',
        target_files: {},
        locales: [],
        source_locale: nil,
        download_path: tmpdir,
        auto_retry: false,
        fail_on_error: true
      )
    end
  end

  it 'keeps fail_on_error disabled by default' do
    option = described_class.available_options.find { |item| item.key == :fail_on_error }

    expect(option.default_value).to be(false)
  end
end
