require 'net/http'
require 'json'

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

module Fastlane
  module Helper
    class MetadataDownloader
      attr_reader :target_folder, :target_files

      def initialize(target_folder, target_files, auto_retry)
        @target_folder = target_folder
        @target_files = target_files
        @auto_retry = auto_retry
        @alternates = {}
        @auto_retry_attempt_counter = 0
      end

      # Downloads data from GlotPress, in JSON format
      def download(target_locale, glotpress_url, is_source)
        downloader = GlotPressDownloader.new(auto_retry: @auto_retry)
        response = downloader.download(glotpress_url)
        handle_glotpress_download(response: response, locale: target_locale, is_source: is_source)
      end

      # Parse JSON data and update the local files
      def parse_data(target_locale, loc_data, is_source)
        delete_existing_metadata(target_locale)

        if loc_data.nil?
          UI.message "No translation available for #{target_locale}"
          return
        end

        loc_data.each do |d|
          key = d[0].split(/\u0004/).first
          source = d[0].split(/\u0004/).last

          target_files.each do |file|
            next unless file[0].to_s == key

            data = file[1]
            msg = is_source ? source : d[1].first || '' # In the JSON, each Hash value is an array, with zero or one entry
            update_key(target_locale, key, file, data, msg)
          end
        end
      end

      # Parse JSON data and update the local files
      def reparse_alternates(target_locale, loc_data, is_source)
        loc_data.each do |d|
          key = d[0].split(/\u0004/).first
          source = d[0].split(/\u0004/).last

          @alternates.each do |file|
            puts "Data: #{file[0]} - key: #{key}"
            next unless file[0].to_s == key

            puts "Alternate: #{key}"
            data = file[1]
            msg = is_source ? source : d[1].first || '' # In the JSON, each Hash value is an array, with zero or one entry
            update_key(target_locale, key, file, data, msg)
          end
        end
      end

      def update_key(target_locale, key, file, data, msg)
        message_len = msg.length
        if data.key?(:max_size) && (data[:max_size] != 0) && (message_len > data[:max_size])
          if data.key?(:alternate_key)
            UI.message("#{target_locale} translation for #{key} exceeds maximum length (#{message_len}). Switching to the alternate translation.")
            @alternates[data[:alternate_key]] = { desc: data[:desc], max_size: 0 }
          else
            UI.message("Rejecting #{target_locale} translation for #{key}: translation length: #{message_len} - max allowed length: #{data[:max_size]}")
          end
        else
          save_metadata(target_locale, file[1][:desc], msg)
        end
      end

      # Writes the downloaded content to the target file
      def save_metadata(locale, file_name, content)
        file_path = get_target_file_path(locale, file_name)

        dir_path = File.dirname(file_path)
        FileUtils.mkdir_p(dir_path)

        File.open(file_path, 'w') { |file| file.puts(content) }
      end

      # Some small helpers
      def delete_existing_metadata(target_locale)
        @target_files.each do |file|
          file_path = get_target_file_path(target_locale, file[1][:desc])
          FileUtils.rm_f(file_path)
        end
      end

      def get_target_file_path(locale, file_name)
        "#{@target_folder}/#{locale}/#{file_name}"
      end

      private

      def handle_glotpress_download(response:, locale:, is_source:)
        case response.code
        when '200'
          # All good, parse the result
          UI.success("Successfully downloaded `#{locale}`.")
          @alternates.clear
          loc_data = JSON.parse(response.body) rescue loc_data = nil
          parse_data(locale, loc_data, is_source)
          reparse_alternates(target_locale, loc_data, is_source) unless @alternates.empty?
        else
          message = "Received unexpected #{response.code} from request to URI #{response.uri}."
          UI.abort_with_message!(message) unless UI.confirm("#{message} Continue anyway?")
        end
      end
    end
  end
end
