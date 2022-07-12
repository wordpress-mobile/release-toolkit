require 'net/http'
require 'json'

module Fastlane
  module Helper
    class MetadataDownloader
      attr_reader :target_folder, :target_files

      def initialize(target_folder, target_files)
        @target_folder = target_folder
        @target_files = target_files
        @alternates = {}
      end

      # Downloads data from GlotPress, in JSON format
      def download(target_locale, glotpress_url, is_source)
        uri = URI(glotpress_url)
        response = Net::HTTP.get_response(uri)
        response = Net::HTTP.get_response(URI.parse(response.header['location'])) if response.code == '301'

        @alternates.clear
        loc_data = JSON.parse(response.body) rescue loc_data = nil
        parse_data(target_locale, loc_data, is_source)
        reparse_alternates(target_locale, loc_data, is_source) unless @alternates.length == 0
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
            if file[0].to_s == key
              data = file[1]
              msg = is_source ? source : d[1].first || '' # In the JSON, each Hash value is an array, with zero or one entry
              update_key(target_locale, key, file, data, msg)
            end
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
            if file[0].to_s == key
              puts "Alternate: #{key}"
              data = file[1]
              msg = is_source ? source : d[1].first || '' # In the JSON, each Hash value is an array, with zero or one entry
              update_key(target_locale, key, file, data, msg)
            end
          end
        end
      end

      def update_key(target_locale, key, file, data, msg)
        message_len = msg.length
        if (data.key?(:max_size)) && (data[:max_size] != 0) && ((message_len) > data[:max_size])
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
        FileUtils.mkdir_p(dir_path) unless File.exist?(dir_path)

        File.open(file_path, 'w') { |file| file.puts(content) }
      end

      # Some small helpers
      def delete_existing_metadata(target_locale)
        @target_files.each do |file|
          file_path = get_target_file_path(target_locale, file[1][:desc])
          File.delete(file_path) if File.exist? file_path
        end
      end

      def get_target_file_path(locale, file_name)
        "#{@target_folder}/#{locale}/#{file_name}"
      end
    end
  end
end
