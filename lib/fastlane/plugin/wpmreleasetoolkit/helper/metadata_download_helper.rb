# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative 'glotpress_downloader'

module Fastlane
  module Helper
    class MetadataDownloader
      attr_reader :target_folder, :target_files

      def initialize(target_folder, target_files, auto_retry, fail_on_error: false)
        @target_folder = target_folder
        @target_files = target_files
        @auto_retry = auto_retry
        @fail_on_error = fail_on_error
        @alternates = {}
      end

      # Downloads data from GlotPress, in JSON format
      def download(target_locale, glotpress_url, is_source)
        GlotPressDownloader.download(
          url: glotpress_url,
          locale: target_locale,
          auto_retry: @auto_retry,
          fail_on_error: @fail_on_error
        ) do |response_body|
          handle_glotpress_response(response_body: response_body, locale: target_locale, is_source: is_source, url: glotpress_url)
        end
      end

      # Parse JSON data and update the local files
      def parse_data(target_locale, loc_data, is_source)
        delete_existing_metadata(target_locale)

        if loc_data.nil?
          UI.message "No translation available for #{target_locale}"
          return
        end

        loc_data.each do |d|
          key = d[0].split("\u0004").first
          source = d[0].split("\u0004").last

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
          key = d[0].split("\u0004").first
          source = d[0].split("\u0004").last

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

      def handle_glotpress_response(response_body:, locale:, is_source:, url:)
        # Parse the JSON response
        @alternates.clear
        loc_data = parse_metadata_response(response_body: response_body, locale: locale, url: url)

        parse_data(locale, loc_data, is_source)
        reparse_alternates(locale, loc_data, is_source) unless @alternates.empty?
      end

      def parse_metadata_response(response_body:, locale:, url:)
        return JSON.parse(response_body) unless @fail_on_error

        loc_data = JSON.parse(response_body)
        UI.user_error!("Unexpected GlotPress metadata response for locale `#{locale}` (#{url})") unless valid_metadata_response?(loc_data)
        loc_data
      rescue JSON::ParserError, TypeError => e
        UI.user_error!("Error parsing GlotPress response for locale `#{locale}` — #{e.message} (#{url})") if @fail_on_error
        nil
      end

      def valid_metadata_response?(loc_data)
        return loc_data.empty? if loc_data.is_a?(Array)
        return false unless loc_data.is_a?(Hash) && !loc_data.empty?

        loc_data.all? do |source, translations|
          source.is_a?(String) && translations.is_a?(Array) && translations.all?(String)
        end
      end
    end
  end
end
