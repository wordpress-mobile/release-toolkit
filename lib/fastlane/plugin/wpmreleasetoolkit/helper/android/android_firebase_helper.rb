require 'json'

module Fastlane
  module Helper
    module Android
      module FirebaseHelper
        class FirebaseDevice
          attr_reader :model, :version, :locale, :orientation

          def initialize(model:, version:, orientation:, locale: 'en')
            raise 'Invalid Model' unless FirebaseDevice.valid_model_names.include? model
            raise 'Invalid Version' unless FirebaseDevice.valid_version_numbers.include? version
            raise 'Invalid Locale' unless FirebaseDevice.valid_locales.include? locale
            raise 'Invalid Orientation' unless FirebaseDevice.valid_orientations.include? orientation

            @model = model
            @version = version
            @locale = locale
            @orientation = orientation
          end

          def to_s
            "model=#{@model},version=#{@version},locale=#{@locale},orientation=#{@orientation}"
          end

          def self.valid_model_names
            JSON.parse(model_data).map { |device| device['codename'] }
          end

          def self.valid_version_numbers
            JSON.parse(version_data).map { |version| version['apiLevel'].to_i }
          end

          def self.valid_locales
            JSON.parse(locale_data).map { |locale| locale['id'] }
          end

          def self.valid_orientations
            %w[portrait landscape]
          end

          def self.model_data
            `gcloud firebase test android models list --format="json"`
          end

          def self.version_data
            `gcloud firebase test android versions list --format="json"`
          end

          def self.locale_data
            `gcloud firebase test android locales list --format="json"`
          end
        end

        def self.run_tests(apk_path:, test_apk_path:, device:, type: 'instrumentation')
          raise "Unable to find apk: #{apk_path}" unless File.file? apk_path
          raise "Unable to find apk: #{test_apk_path}" unless File.file? test_apk_path
          raise "Invalid Type: #{type}" unless %w[instrumentation robo].include? type

          Action.sh(
            'gcloud', 'firebase', 'test', 'android', 'run',
            '--type', type,
            '--app', apk_path,
            '--test', test_apk_path,
            '--device', device.to_s
          )
        end

        def self.project=(project_id)
          Action.sh('gcloud', 'config', 'set', 'project', project_id)
        end

        def self.setup(key_file:)
          raise "Unable to find key file: #{key_file}" unless File.file? key_file

          Action.sh(
            'gcloud', 'auth', 'activate-service-account',
            '--key-file', key_file
          )
        end

        def self.has_gcloud_binary
          UI.user_error!("The `gcloud` binary isn't available on this machine. Unable to continue.") unless system('command -v gcloud > /dev/null')
        end
      end
    end
  end
end
