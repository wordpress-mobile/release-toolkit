require 'tmpdir'

module Fastlane
  module Helper
   
    class PromoScreenshots
      attr_reader :device, :locales, :orig_folder, :target_folder, :default_locale, :metadata_folder

      def initialize(locales, default_locale, orig_folder, target_folder, metadata_folder)
        @locales = locales
        @default_locale = default_locale
        @orig_folder = orig_folder
        @target_folder = target_folder
        @metadata_folder = metadata_folder

        load_default_locale()
      end

      # Generate all the required screenshots for
      # the provided device
      def generate_device(device)
        @device = device
        UI.message("Generate promo screenshot for device: #{@device[:device]}")

        locales.each do | locale |
          generate_locale(locale)
        end
      end

      # Download the used font to the tmp folder
      # if it's not there
      def self.require_font()
        font_file = self.get_font_path()
        if (File.exist?(font_file))
          return
        end

        font_folder = File.dir_name(font_file)
        Dir.mkdir() unless File.exist?(font_folder)
        Fastlane::Actions::sh("wget \"https://fonts.google.com/download?family=Noto%20Serif\" -O \"#{font_folder}/noto.zip\"")
        Fastlane::Actions::sh("unzip \"#{font_folder}/noto.zip\" -d \"#{font_folder}\"")
      end

      private
      # Generate the screenshots for
      # the provided locale
      def generate_locale(locale)
        UI.message("Generating #{locale}...")

        target_folder = verify_target_folder(locale)
        strings = get_promo_strings_for(locale)
        files = Dir["#{get_screenshots_orig_path(locale)}#{@device[:device]}*"].sort

        idx = 0
        files.each do | file |
          generate_screenshot(file, get_local_at(0, strings), target_folder)
        end
      end

      # Generate a promo screenshot
      def generate_screenshot(file, string, target_folder)
        target_file = "#{target_folder}#{File.basename(file)}"
        puts "Generate screenshots for #{file} to #{target_file}"

        # Temp file paths
        resized_file = "#{target_file}_resize"
        comp_file = "#{target_file}_comp"
        
        # 1. Resize original screenshot
        Fastlane::Actions::sh("magick \"#{file}\" -resize 924x1640 \"#{resized_file}\"")
        
        # 2. Put it on the background
        Fastlane::Actions::sh("magick #{@device[:template]} \"#{resized_file}\" -geometry +161+568 -composite \"#{comp_file}\"")
        File.delete(resized_file) if File.exist?(resized_file)

        # 3. Put the promo string on top of it
        Fastlane::Actions::sh("magick \"#{comp_file}\" -gravity north -pointsize 80 -font #{self.get_font_path()} -draw \"fill white text 0,58 \\\"#{string}\\\"\" \"#{target_file}\"")
        File.delete(comp_file) if File.exist?(comp_file)
      end

      # Loads the promo strings in the default locale
      # -> to be used when a localisation is missing
      def load_default_locale()
        @default_strings = get_promo_strings_for(@default_locale)
      end

      # Gets the promo string, picking the default one
      # if the localised version is missing
      def get_local_at(index, strings)
        if (strings.key?(index.to_s))
          return strings[index.to_s]
        end

        if (@default_strings.key?(index.to_s))
          return @default_strings[index.to_s]
        end
        
        return "Unknown"
      end

      # Loads the localised promo string set for
      # the provided locale
      def get_promo_strings_for(locale)
        strings = { }

        path = get_locale_path(locale)
        files = Dir["#{path}*"]

        files.each do | promo_file |
          # Extract the string ID code
          promo_file_name = File.basename(promo_file, ".txt")
          promo_id = promo_file_name.split('_').last

          # Read the file into a string
          promo_string = File.read(promo_file)
          
          # Add to hash
          strings[promo_id] = promo_string
        end

        return strings
      end 

      # Helpers
      def verify_target_folder(locale)
        folder = get_screenshots_target_path(locale)
        Dir.mkdir(folder) unless File.exists?(folder)

        return folder
      end

      def get_locale_path(locale)
        "#{@metadata_folder}/#{locale}/"
      end

      def get_screenshots_orig_path(locale)
        "#{@orig_folder}/#{locale}/"
      end

      def get_screenshots_target_path(locale)
        "#{@target_folder}/#{locale}/"
      end

      def self.get_font_path()
        "#{Dir.tmpdir()}/font/NotoSerif-Bold.ttf"
      end
    end
  end
end
