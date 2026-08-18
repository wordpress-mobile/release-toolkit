# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Helper::MetadataDownloader do
  let(:test_url) { 'https://translate.wordpress.org/projects/test/locale/default/export-translations/' }
  let(:downloader) { described_class.new('/tmp/metadata', {}, false) }

  it 'propagates download failures' do
    stub_request(:get, test_url).to_return(status: 500)
    allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)

    expect do
      downloader.download('fr', test_url, false)
    end.to raise_error(Fastlane::Helper::GlotPressDownloader::DownloadError, /500/)
  end

  it 'raises when the downloaded metadata is not valid JSON' do
    stub_request(:get, test_url).to_return(status: 200, body: '{')

    expect do
      downloader.download('fr', test_url, false)
    end.to raise_error(FastlaneCore::Interface::FastlaneError, /Error parsing GlotPress response for locale `fr`/)
  end
end
