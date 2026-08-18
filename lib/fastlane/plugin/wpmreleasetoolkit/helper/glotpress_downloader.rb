# frozen_string_literal: true

require 'net/http'
require 'uri'

module Fastlane
  module Helper
    # A helper class to download files from GlotPress with proper error handling and retry mechanism
    class GlotPressDownloader
      AUTO_RETRY_SLEEP_TIME = 20
      MAX_AUTO_RETRY_ATTEMPTS = 30
      MAX_REDIRECTS = 10

      attr_reader :auto_retry, :auto_retry_attempt_counter, :url, :locale, :fail_on_error

      # Initialize a new GlotPressDownloader
      #
      # @param [String] url The URL to download from
      # @param [String] locale The locale being downloaded (for logging purposes)
      # @param [Boolean] auto_retry Whether to automatically retry on rate limiting (429 errors)
      # @param [Boolean] fail_on_error Whether to raise a Fastlane error after retry handling instead of returning false
      #
      def initialize(url:, locale:, auto_retry: false, fail_on_error: false)
        @url = url
        @locale = locale
        @auto_retry = auto_retry
        @fail_on_error = fail_on_error
        @auto_retry_attempt_counter = 0
      end

      # Convenience class method to download in a single call
      #
      # @param [String] url The URL to download from
      # @param [String] locale The locale being downloaded (for logging purposes)
      # @param [Boolean] auto_retry Whether to automatically retry on rate limiting (429 errors)
      # @param [Boolean] fail_on_error Whether to raise a Fastlane error after retry handling instead of returning false
      # @yield [String] The response body if the download was successful
      # @return The result of the block if provided, or true/false indicating success if no block is provided
      # @raise [FastlaneCore::Interface::FastlaneError] If the download fails after retry handling and `fail_on_error` is true
      #
      def self.download(url:, locale:, auto_retry: false, fail_on_error: false, &)
        new(url: url, locale: locale, auto_retry: auto_retry, fail_on_error: fail_on_error).download(&)
      end

      # Downloads data from GlotPress
      #
      # @yield [String] The response body if the download was successful
      # @return The result of the block if provided, or true/false indicating success if no block is provided
      # @raise [FastlaneCore::Interface::FastlaneError] If the download fails after retry handling and `fail_on_error` is true
      #
      def download(&)
        @auto_retry_attempt_counter = 0 # Reset counter only at start of download
        download_from_url(@url, redirect_count: 0, &)
      end

      private

      def download_from_url(url, redirect_count:, &)
        uri = parse_uri(url)
        return block_given? ? nil : false if uri.nil?

        response = make_request(uri)
        return block_given? ? nil : false if response.nil?

        unless block_given?
          return handle_response(response: response, url: url, original_uri: uri, redirect_count: redirect_count)
        end

        result = nil
        handle_response(response: response, url: url, original_uri: uri, redirect_count: redirect_count) do |body|
          result = yield(body)
        end
        result
      end

      def parse_uri(url)
        uri = URI(url)
        return uri if uri.is_a?(URI::HTTP) && uri.host

        handle_failure("Invalid URL for locale `#{@locale}` (#{url})")
        nil
      rescue URI::InvalidURIError, TypeError => e
        handle_failure("Invalid URL for locale `#{@locale}` — #{e.message} (#{url})")
        nil
      end

      def make_request(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = Wpmreleasetoolkit::USER_AGENT
        http.request(request)
      rescue StandardError => e
        # Network errors, connection errors, etc.
        message = "Error downloading locale `#{@locale}` — #{e.message} (#{uri})"
        retry if UI.interactive? && UI.confirm("Retry downloading `#{@locale}`?")
        handle_failure(message)
        nil
      end

      def handle_response(response:, url:, original_uri:, redirect_count:, &)
        case response.code
        when '200'
          yield(response.body) if block_given?
          UI.success("Successfully downloaded `#{@locale}`.")
          true
        when '301', '302', '307', '308'
          # Follow the redirect
          UI.message("Received #{response.code} for `#{@locale}`. Following redirect...")
          redirect_url = response['location']
          return handle_failure("Received #{response.code} for `#{@locale}` but no location header was found (#{original_uri}).") if redirect_url.nil? || redirect_url.empty?
          return handle_failure("Too many redirects while downloading locale `#{@locale}` (#{original_uri}).") if redirect_count >= MAX_REDIRECTS

          resolved_url = resolve_redirect_url(original_uri, redirect_url)
          return false if resolved_url.nil?

          download_from_url(resolved_url, redirect_count: redirect_count + 1, &)
        when '429'
          # Rate limited
          handle_rate_limiting(url: url, response: response, redirect_count: redirect_count, &)
        else
          # Unexpected status code (including 404, 500, etc.)
          status_line = [response.code, response.message].compact.join(' ').strip
          message = "Error downloading locale `#{@locale}` — #{status_line} (#{original_uri})"
          return handle_failure(message) unless UI.interactive? && UI.confirm("Retry downloading `#{@locale}`?")

          download_from_url(url, redirect_count: redirect_count, &)
        end
      end

      def handle_rate_limiting(url:, response:, redirect_count:, &)
        if @auto_retry && @auto_retry_attempt_counter < MAX_AUTO_RETRY_ATTEMPTS
          UI.message("Received 429 for `#{@locale}`. Auto retrying in #{AUTO_RETRY_SLEEP_TIME} seconds... (attempt #{@auto_retry_attempt_counter + 1}/#{MAX_AUTO_RETRY_ATTEMPTS})")
          sleep(AUTO_RETRY_SLEEP_TIME)
          @auto_retry_attempt_counter += 1
          download_from_url(url, redirect_count: redirect_count, &)
        elsif UI.interactive? && UI.confirm("Retry downloading `#{@locale}` after receiving 429 from the API?")
          download_from_url(url, redirect_count: redirect_count, &)
        else
          status_line = [response.code, response.message].compact.join(' ').strip
          handle_failure("Error downloading locale `#{@locale}` — #{status_line} (#{url})")
        end
      end

      def resolve_redirect_url(original_uri, redirect_url)
        URI.join(original_uri.to_s, redirect_url).to_s
      rescue URI::InvalidURIError => e
        handle_failure("Invalid redirect URL for locale `#{@locale}` — #{e.message} (#{redirect_url})")
        nil
      end

      def handle_failure(message)
        UI.error(message)
        UI.user_error!(message) if @fail_on_error
        false
      end
    end
  end
end
