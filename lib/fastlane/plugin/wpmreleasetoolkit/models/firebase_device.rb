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

    def self.locale_data
      Fastlane::Actions.sh('gcloud firebase test android locales list --format="json"', log: false)
    end

    def self.model_data
      Fastlane::Actions.sh('gcloud firebase test android models list --format="json"', log: false)
    end

    def self.version_data
      Fastlane::Actions.sh('gcloud firebase test android versions list --format="json"', log: false)
    end
  end
end
