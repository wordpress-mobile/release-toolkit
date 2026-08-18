# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Helper::MetadataDownloader do
  let(:test_url) { 'https://translate.wordpress.org/projects/test/locale/default/export-translations/' }
  let(:target_files) { { release_notes: { desc: 'release_notes.txt', max_size: 0 } } }

  def existing_metadata_file(tmpdir)
    path = File.join(tmpdir, 'fr', 'release_notes.txt')
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, 'Existing release notes')
    path
  end

  it 'propagates download failures' do
    stub_request(:get, test_url).to_return(status: 500)
    allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)

    in_tmp_dir do |tmpdir|
      downloader = described_class.new(tmpdir, target_files, false)

      expect do
        downloader.download('fr', test_url, false)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /500/)
    end
  end

  ['{', 'null', '42', '{}', '["unexpected"]', '{"error":"maintenance"}'].each do |response_body|
    it "raises without deleting existing metadata for an invalid response body: #{response_body}" do
      stub_request(:get, test_url).to_return(status: 200, body: response_body)

      in_tmp_dir do |tmpdir|
        existing_file = existing_metadata_file(tmpdir)
        downloader = described_class.new(tmpdir, target_files, false)

        expect { downloader.download('fr', test_url, false) }.to raise_error(FastlaneCore::Interface::FastlaneError, /GlotPress.*locale `fr`.*#{Regexp.escape(test_url)}/)
        expect(File.read(existing_file)).to eq('Existing release notes')
      end
    end
  end

  it 'accepts a legitimate empty export and removes stale metadata' do
    stub_request(:get, test_url).to_return(status: 200, body: '[]')

    in_tmp_dir do |tmpdir|
      existing_file = existing_metadata_file(tmpdir)
      downloader = described_class.new(tmpdir, target_files, false)

      downloader.download('fr', test_url, false)

      expect(File).not_to exist(existing_file)
    end
  end
end
