# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Helper::GlotPressDownloader do
  let(:test_url) { 'https://translate.wordpress.org/projects/test/locale/default/export-translations/' }
  let(:locale) { 'test-locale' }

  describe 'successful downloads' do
    it 'downloads successfully with 200 status' do
      stub_request(:get, test_url)
        .to_return(status: 200, body: 'test content')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false)
      result = nil
      downloader.download { |body| result = body }

      expect(result).to eq('test content')
    end

    it 'returns true when downloading without a block' do
      stub_request(:get, test_url)
        .to_return(status: 200, body: 'test content')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false)

      expect(downloader.download).to be(true)
    end

    it 'does not report success until the downloaded body has been accepted' do
      stub_request(:get, test_url)
        .to_return(status: 200, body: 'invalid content')
      expect(FastlaneCore::UI).not_to receive(:success)

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false)

      expect do
        downloader.download { raise 'invalid downloaded body' }
      end.to raise_error(RuntimeError, 'invalid downloaded body')
    end

    it 'does not report success when the downloaded body is rejected' do
      stub_request(:get, test_url)
        .to_return(status: 200, body: 'rejected content')
      expect(FastlaneCore::UI).not_to receive(:success)

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false)

      expect(downloader.download { false }).to be(false)
    end

    it 'resets retry counter at start of download' do
      # Counter should be reset to 0 at the start of download() call
      downloader = described_class.new(url: test_url, locale: locale, auto_retry: true)

      # Manually set counter to simulate previous state
      downloader.instance_variable_set(:@auto_retry_attempt_counter, 5)
      expect(downloader.auto_retry_attempt_counter).to eq(5)

      # After download starts, counter should be reset
      stub_request(:get, test_url)
        .to_return(status: 200, body: 'success')

      downloader.download { |body| body }

      # Counter reset to 0 at start, no retries needed, so still 0
      expect(downloader.auto_retry_attempt_counter).to eq(0)
    end

    it 'preserves retry counter value after successful retry' do
      # Counter should reflect the number of retries that occurred
      stub_request(:get, test_url)
        .to_return(status: 429)
        .then.to_return(status: 200, body: 'success')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: true)
      allow(downloader).to receive(:sleep).with(20)

      downloader.download { |body| body }

      # Counter shows 1 retry occurred
      expect(downloader.auto_retry_attempt_counter).to eq(1)
    end
  end

  describe 'rate limiting (429) with auto_retry' do
    it 'automatically retries on 429 when auto_retry is enabled' do
      stub_request(:get, test_url)
        .to_return(status: 429)
        .then.to_return(status: 200, body: 'success after retry')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: true)
      result = nil

      # Stub sleep globally to avoid waiting 20 seconds
      allow(downloader).to receive(:sleep).with(20)

      downloader.download { |body| result = body }

      expect(result).to eq('success after retry')
      expect(a_request(:get, test_url)).to have_been_made.times(2)
    end

    it 'increments retry counter on each retry attempt' do
      # Fail with 429 three times, then succeed
      stub_request(:get, test_url)
        .to_return(status: 429)
        .then.to_return(status: 429)
        .then.to_return(status: 429)
        .then.to_return(status: 200, body: 'finally success')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: true)
      allow(downloader).to receive(:sleep).with(20)

      downloader.download { |body| body }

      # Counter shows 3 retries occurred
      expect(downloader.auto_retry_attempt_counter).to eq(3)
      expect(a_request(:get, test_url)).to have_been_made.times(4)
    end

    it 'stops retrying after max attempts' do
      stub_request(:get, test_url).to_return(status: 429)

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: true, fail_on_error: true)
      allow(downloader).to receive(:sleep).with(20)

      # Mock non-interactive environment to avoid prompts
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)
      expect(FastlaneCore::UI).to receive(:error).with(/Error downloading locale `test-locale` — 429.*#{Regexp.escape(test_url)}/)

      expect do
        downloader.download { |body| body }
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /429/)

      # Should try: 1 initial + 30 retries = 31 total
      expect(a_request(:get, test_url)).to have_been_made.times(31)
    end

    it 'does not auto-retry when auto_retry is disabled' do
      stub_request(:get, test_url).to_return(status: 429)

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false, fail_on_error: true)

      # Mock UI methods to avoid prompts
      allow(FastlaneCore::UI).to receive(:error)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)

      expect do
        downloader.download { |body| body }
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /429/)

      # Should only try once (no auto-retry)
      expect(a_request(:get, test_url)).to have_been_made.once
    end
  end

  describe 'redirects' do
    it 'follows 301 redirects' do
      redirect_url = 'https://translate.wordpress.org/redirected'
      stub_request(:get, test_url)
        .to_return(status: 301, headers: { 'Location' => redirect_url })
      stub_request(:get, redirect_url)
        .to_return(status: 200, body: 'redirected content')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false)
      result = nil
      downloader.download { |body| result = body }

      expect(result).to eq('redirected content')
      expect(a_request(:get, test_url)).to have_been_made.once
      expect(a_request(:get, redirect_url)).to have_been_made.once
    end

    it 'resolves relative redirect locations' do
      redirect_url = 'https://translate.wordpress.org/redirected'
      stub_request(:get, test_url)
        .to_return(status: 302, headers: { 'Location' => '/redirected' })
      stub_request(:get, redirect_url)
        .to_return(status: 200, body: 'redirected content')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false)

      expect(downloader.download).to be(true)
      expect(a_request(:get, redirect_url)).to have_been_made.once
    end

    it 'raises when a redirect has no location header' do
      stub_request(:get, test_url).to_return(status: 302)

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false, fail_on_error: true)

      expect do
        downloader.download { |body| body }
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "Received 302 for `test-locale` but no location header was found (#{test_url}).")
    end

    it 'raises when the maximum number of redirects is exceeded' do
      stub_request(:get, test_url)
        .to_return(status: 302, headers: { 'Location' => test_url })

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false, fail_on_error: true)

      expect { downloader.download { |body| body } }.to raise_error(FastlaneCore::Interface::FastlaneError, /Too many redirects/)
      expect(a_request(:get, test_url)).to have_been_made.times(described_class::MAX_REDIRECTS + 1)
    end
  end

  describe 'error handling' do
    it 'returns falsey results by default' do
      stub_request(:get, test_url).to_return(status: 404, body: 'Not Found')
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)
      allow(FastlaneCore::UI).to receive(:error)

      downloader = described_class.new(url: test_url, locale: locale)

      expect(downloader.download { |body| body }).to be_nil
      expect(downloader.download).to be(false)
      expect(a_request(:get, test_url)).to have_been_made.times(2)
    end

    it 'raises on 404 errors in non-interactive mode' do
      stub_request(:get, test_url).to_return(status: 404, body: 'Not Found')

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false, fail_on_error: true)

      # Mock non-interactive environment
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)
      allow(FastlaneCore::UI).to receive(:error)

      expect do
        downloader.download { |body| body }
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /404/)
      expect(a_request(:get, test_url)).to have_been_made.once
    end

    it 'raises on SSL errors in non-interactive mode' do
      stub_request(:get, test_url).to_raise(OpenSSL::SSL::SSLError.new('certificate verify failed'))

      downloader = described_class.new(url: test_url, locale: locale, auto_retry: false, fail_on_error: true)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)
      allow(FastlaneCore::UI).to receive(:error)

      expect do
        downloader.download { |body| body }
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /certificate verify failed/)
      expect(a_request(:get, test_url)).to have_been_made.once
    end

    it 'raises a clean user error for invalid URLs' do
      invalid_url = 'https://translate.wordpress.org/an invalid path'
      downloader = described_class.new(url: invalid_url, locale: locale, auto_retry: false, fail_on_error: true)

      expect { downloader.download { |body| body } }.to raise_error(FastlaneCore::Interface::FastlaneError, /Invalid URL for locale `test-locale`.*an invalid path/)
    end
  end
end
