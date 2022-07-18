module Fastlane
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

    class << self
      @locale_data = nil
      @model_data = nil
      @version_data = nil

      def valid_model_names
        JSON.parse(model_data).map { |device| device['codename'] }
      end

      def valid_version_numbers
        JSON.parse(version_data).map { |version| version['apiLevel'].to_i }
      end

      def valid_locales
        JSON.parse(locale_data).map { |locale| locale['id'] }
      end

      def valid_orientations
        %w[portrait landscape]
      end

      def locale_data
        FirebaseDevice.verify_logged_in!
        @locale_data ||= Fastlane::Actions.sh('gcloud', 'firebase', 'test', 'android', 'locales', 'list', '--format="json"', log: false)
      end

      def model_data
        FirebaseDevice.verify_logged_in!
        @model_data ||= Fastlane::Actions.sh('gcloud', 'firebase', 'test', 'android', 'models', 'list', '--format="json"', log: false)
      end

      def version_data
        FirebaseDevice.verify_logged_in!
        @version_data ||= Fastlane::Actions.sh('gcloud', 'firebase', 'test', 'android', 'versions', 'list', '--format="json"', log: false)
      end

      def verify_logged_in!
        UI.user_error!('You must call `firebase_login` before creating a FirebaseDevice object') unless FirebaseAccount.authenticated?
      end
    end
  end
end
