require 'spec_helper'

describe Fastlane::Helper::GlotpressDownloader do
  describe 'downloading' do
    context 'when auto retry is enabled' do
      context 'when GlotPress returs a 429 code' do
        it 'retries automatically' do
          sleep_time = 0.1
          downloader = described_class.new(auto_retry: true, auto_retry_sleep_time: sleep_time)
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
            .with(/Received 429 for `#{fake_url}`. Auto retrying in #{sleep_time} seconds.../)

          response = downloader.download(fake_url)

          expect(count).to eq(2)
          expect(response.code).to eq('200')
        end

        context 'when the maximum number of retries is reached' do
          it 'aborts' do
            sleep_time = 0.1
            max_retries = 3
            downloader = described_class.new(auto_retry: true, auto_retry_sleep_time: sleep_time, auto_retry_max_attempts: max_retries)
            fake_url = 'https://test.com'

            count = 0
            stub_request(:get, fake_url).to_return do
              count += 1
              { status: 429, body: 'Too Many Requests' }
            end

            expect(Fastlane::UI).to receive(:message)
              .with(/Received 429 for `#{fake_url}`. Auto retrying in #{sleep_time} seconds.../)
              .exactly(max_retries).times

            expect(Fastlane::UI).to receive(:error)
              .with(/Abandoning `#{fake_url}` download after #{max_retries} retries./)

            downloader.download(fake_url)

            expect(count).to eq(max_retries + 1) # the original request plus the retries
          end
        end
      end
    end
  end
end
