require 'net/http'

module Fastlane
  module Helper
    class GlotpressDownloader
      AUTO_RETRY_SLEEP_TIME = 20
      MAX_AUTO_RETRY_ATTEMPTS = 30

      def initialize(
        auto_retry: true,
        auto_retry_sleep_time: 20,
        auto_retry_max_attempts: 30
      )
        @auto_retry = auto_retry
        @auto_retry_sleep_time = auto_retry_sleep_time
        @auto_retry_max_attempts = auto_retry_max_attempts
        @auto_retry_attempt_counter = 0
      end

      def download(glotpress_url)
        uri = URI(glotpress_url)
        response = Net::HTTP.get_response(uri)

        case response.code
        when '200' # All good pass the result along
          response
        when '301' # Follow the redirect
          UI.message("Received 301 for `#{response.uri}`. Following redirect...")
          download(response.header['location'])
        when '429' # We got rate-limited, auto_retry or offer to try again with a prompt
          if @auto_retry
            if @auto_retry_attempt_counter < @auto_retry_max_attempts
              UI.message("Received 429 for `#{response.uri}`. Auto retrying in #{@auto_retry_sleep_time} seconds...")
              sleep(@auto_retry_sleep_time)
              @auto_retry_attempt_counter += 1
              download(response.uri)
            else
              UI.error("Abandoning `#{response.uri}` download after #{@auto_retry_attempt_counter} retries.")
            end
          elsif UI.confirm("Retry downloading `#{response.uri}` after receiving 429 from the API?")
            download(response.uri)
          else
            UI.error("Abandoning `#{response.uri}` download as requested.")
          end
        else
          message = "Received unexpected #{response.code} from request to URI #{response.uri}."
          UI.abort_with_message!(message) unless UI.confirm("#{message} Continue anyway?")
        end
      end
    end
  end
end
