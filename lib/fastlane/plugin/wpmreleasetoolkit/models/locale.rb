require 'fastlane_core/ui/ui'

module Fastlane
  module Wpmreleasetoolkit
    Locale = Struct.new(:glotpress, :android, :playstore, :ios, :appstore, keyword_init: true) do
      def android_path
        File.join("values-#{self.android}", 'strings.xml')
      end

      def ios_path
        File.join("#{self.ios}.lproj", 'Localizable.strings')
      end

      def self.valid?(locale, *keys)
        if locale.nil?
          UI.warning("Locale is unknown")
          return false
        end
        keys.each do |key|
          if locale[key].nil?
            UI.warning("Locale #{locale} is missing required key #{key}")
            return false
          end
        end
        return true
      end
    end
  end
end
