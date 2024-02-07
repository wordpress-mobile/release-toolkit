require 'spaceship'

module Fastlane
  module Helper
    module Ios
      module ADCAppSizesHelper
        DEFAULT_DEVICES = ['Universal', 'iPhone 8', 'iPhone X'].freeze

        # Fetch the App Sizes stats from ADC
        #
        # @return [Array<Hash>] app build details, one entry per app version found
        #         Each entry is a hash with keys `cfBundleVersion` and `sizesInBytes`.
        #         Value for key `sizeInBytes` is itself a Hash with one entry per device name (including special name "Universal")
        #         whose value is a Hash with keys `compressed` and `uncompressed`
        #
        def self.get_adc_sizes(adc_user:, bundle_id:, adc_team: 'Automattic, Inc.', only_version: nil, limit: 10)
          UI.message 'Connecting to ADC...'
          Spaceship::ConnectAPI.login(adc_user, team_name: adc_team)
          app = Spaceship::ConnectAPI::App.find(bundle_id)

          UI.message 'Fetching the list of versions...'
          versions = app.app_store_versions.select { |v| v.version_string == only_version && !v.build.nil? }
          versions = app.get_app_store_versions.reject { |v| v.build.nil? } if versions.empty?
          UI.message "Found #{versions.count} versions." + (limit.zero? ? '' : " Limiting to last #{limit}")
          versions = versions.first(limit) unless limit.zero?

          UI.message 'Fetching App Sizes...'

          builds_details = versions.each_with_index.map do |v, idx|
            print "Fetching info for: #{v.version_string.rjust(8)} (#{v.build.version.rjust(11)}) [#{idx.to_s.rjust(3)}/#{versions.count}]\r"
            begin
              Spaceship::Tunes.client.build_details(app_id: app.id, train: v.version_string, build_number: v.build.version, platform: 'ios')
            rescue StandardError
              nil
            end
          end.compact.reverse
          print("#{' ' * 55}\n")

          builds_details
        end

        def self.sz(bytes)
          (bytes.to_f / (1024 * 1024)).round(1)
        end

        def self.sz_mb(bytes)
          "#{sz(bytes).to_s.rjust(5)} MB"
        end

        def self.format_csv(app_sizes, devices: nil)
          devices = DEFAULT_DEVICES if devices.nil? || devices.empty?
          csv = "Version\t#{devices.join("\t")}\n"
          app_sizes.each do |details|
            build_number = details['cfBundleVersion']
            sizes = details['sizesInBytes'].select { |name, _| devices.include?(name) }
            csv += "#{build_number}\t" + devices.map { |d| sz(sizes[d]['compressed']) }.join("\t") + "\n"
          end
          csv
        end

        def self.format_markdown(app_sizes, devices: nil)
          devices = DEFAULT_DEVICES if devices.nil? || devices.empty?
          app_sizes.map do |details|
            build_number = details['cfBundleVersion']
            sizes = details['sizesInBytes'].select { |name, _| devices.include?(name) }
            col_size = devices.map(&:length).max
            table = "| #{build_number.ljust(col_size)} | Download | Install  |\n"
            table += "|:#{'-' * col_size}-|---------:|---------:|\n"
            sizes.each do |(device_name, size_info)|
              table += "| #{device_name.ljust(col_size)} | #{sz_mb(size_info['compressed'])} | #{sz_mb(size_info['uncompressed'])} |\n"
            end
            table
          end
        end
      end
    end
  end
end
