require 'spec_helper'

describe Fastlane::Helper::MetadataDownloader do
  describe 'downloading from GlotPress' do
    it 'save the downloaded data to the target folder and file, including locale name' do
      in_tmp_dir do |tmp_dir|
        destination_name = 'target-file-name.txt'
        dummy_url = 'https://test.com'
        metadata_downloader = described_class.new(tmp_dir, { key: { desc: destination_name } }, true)

        stub_request(:get, dummy_url).to_return(
          status: 200,
          # GlotPress responses have a custom format.
          body: { "key\u0004test metadata" => ['test metadata'] }.to_json
        )

        metadata_downloader.download('en-AU', dummy_url, false)

        destination_path_with_locale = File.join(tmp_dir, 'en-AU', destination_name)
        expect(File.exist?(destination_path_with_locale)).to be true
        # We also expect a trailing new line.
        expect(File.read(destination_path_with_locale)).to eq("test metadata\n")
      end
    end

    context 'when GlotPress returs a 429 code' do
      it 'automatically retries' do
        in_tmp_dir do |tmp_dir|
          metadata_downloader = described_class.new(
            tmp_dir,
            { key: { desc: 'target-file-name.txt' } },
            true,
            0.1
          )

          fake_url = 'https://test.com'

          count = 0
          stub_request(:get, fake_url).to_return do
            count += 1
            if count == 1
              { status: 429, body: 'Too Many Requests' }
            else
              { status: 200, body: 'OK' }
            end
          end

          expect(Fastlane::UI).to receive(:message)
            .with(/Received 429 for `#{fake_url}`. Auto retrying in 0.1 seconds.../)

          expect(Fastlane::UI).to receive(:message)
            .with(/No translation available for en-AU/)

          expect(Fastlane::UI).to receive(:success)
            .with(/Successfully downloaded `en-AU`./)

          metadata_downloader.download('en-AU', fake_url, false)

          assert_requested(:get, fake_url, times: 2)
        end
      end
    end
  end
end
