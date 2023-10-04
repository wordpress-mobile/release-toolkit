require 'spec_helper'

describe Fastlane::Helper::MetadataDownloader do
  describe 'downloading from GlotPress' do
    context 'when GlotPress returs a 429 code' do
      it 'automatically retries' do
        in_tmp_dir do |tmp_dir|
          metadata_downaloder = described_class.new(
            tmp_dir,
            { key: { desc: 'target-file-name.txt' } },
            true
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
            .with(/Received 429 for `#{fake_url}`. Auto retrying in 20 seconds.../)

          expect(Fastlane::UI).to receive(:message)
            .with(/No translation available for en-AU/)

          expect(Fastlane::UI).to receive(:success)
            .with(/Successfully downloaded `en-AU`./)

          metadata_downaloder.download('en-AU', fake_url, false)

          expect(count).to eq(2)
        end
      end
    end
  end
end
