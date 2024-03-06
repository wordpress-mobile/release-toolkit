# NOTE: This is not really a spec but a demo script instead that I used to test my implementation.
# FIXME: Convert this to an actual spec with unit test cases and stubs/fixtures

module GlotpressDownloaderDemo
  DOTORG = 'translate.wordpress.org'
  DOTCOM = 'translate.wordpress.com'
  WP_ANDROID = { host: DOTORG, project: 'apps/android/dev' }
  WP_IOS = { host: DOTORG, project: 'apps/ios/dev' }
  WC_ANDROID = { host: DOTCOM, project: 'woocommerce/woocommerce-android' }
  WC_IOS = { host: DOTCOM, project: 'woocommerce/woocommerce-ios' }

  EXPORT_FMT = Fastlane::Helper::GPDownloader::FORMAT
  FastlaneMetadataFilesWriter = Fastlane::Helper::FastlaneMetadataFilesWriter

  EXAMPLE_OUTPUT_DIR = 'MyTestApp'

  # Example Usages for App Translation

  def demo_android_app_translations_bulk
    output_dir = File.join(EXAMPLE_OUTPUT_DIR, 'src', 'main', 'res')
    FileUtils.mkdir_p(output_dir)
    downloader = Fastlane::Helper::GPDownloader.new(**WC_ANDROID)
    downloader.download_all_locales(format: EXPORT_FMT::ANDROID) do |gp_locale, io|
      locale = Locales.all.find(gp_locale)
      Fastlane::Helper::Android::StringsFileWriter.write(dir: output_dir, locale: locale, io: io) unless locale.nil? # skip unknown locales that may be present in ZIP
    end
  end

  def demo_ios_app_translations_bulk
    output_dir = File.join(EXAMPLE_OUTPUT_DIR, 'Resources')
    FileUtils.mkdir_p(output_dir)
    downloader = Fastlane::Helper::GPDownloader.new(**WC_IOS)
    downloader.download_all_locales(format: EXPORT_FMT::IOS) do |gp_locale, io|
      locale = Locales.all.find(gp_locale)
      Fastlane::Helper::Ios::StringsFileWriter.write(dir: output_dir, locale: locale, io: io) unless locale.nil? # skip unknown locales that may be present in ZIP
    end
  end

  def demo_ios_app_translations_loop
    output_dir = File.join(EXAMPLE_OUTPUT_DIR, 'Resources')
    FileUtils.mkdir_p(output_dir)
    downloader = Fastlane::Helper::GPDownloader.new(**WC_IOS)
    Locales.mag16.each do |locale|
      downloader.download_locale(gp_locale: locale.glotpress, format: EXPORT_FMT::IOS) do |io|
        Fastlane::Helper::Ios::StringsFileWriter.write(dir: output_dir, locale: locale, io: io)
      end
    end
  end

  # Example Usages for Metadata

  def demo_android_metadata_bulk
    downloader = Fastlane::Helper::GPDownloader.new(host: DOTORG, project: 'apps/android/release-notes')
    downloader.download_all_locales(format: EXPORT_FMT::JSON) do |gp_locale, io|
      locale = Locales.mag16.find(gp_locale)
      next unless Locale.valid?(locale, :playstore)

      rules = FastlaneMetadataFilesWriter::MetadataRule.android_rules(version_name: '20.4', version_code: 1234)
      translations = downloader.class.parse_json_export(io: io) # Convert odd GlotPress JSON export format to standard Hash

      locale_dir = File.join(EXAMPLE_OUTPUT_DIR, 'fastlane', 'metadata', 'android', locale.playstore)
      FastlaneMetadataFilesWriter.write(locale_dir: locale_dir, translations: translations, rules: rules) do |key|
        # Example: if we find a non-standard key which ends up being a screenshot key, save under screenshots/ subdir.
        # Otherwise, just ignore any other unknown key.
        if key.start_with?('play_store_screenshot_')
          FastlaneMetadataFilesWriter::MetadataRule.new(key, nil, File.join('screenshots', "#{key.delete_prefix('play_store_screenshot_')}.txt"))
        end
      end
    end
  end

  def demo_android_metadata_loop
    downloader = Fastlane::Helper::GPDownloader.new(host: DOTORG, project: 'apps/android/release-notes/')
    Locales['fr', 'es'].each do |locale|
      next unless Locale.valid?(locale, :playstore)
      downloader.download_locale(gp_locale: locale.glotpress, format: EXPORT_FMT::JSON) do |io|
        locale_dir = File.join(EXAMPLE_OUTPUT_DIR, 'fastlane', 'metadata', 'android', locale.playstore)
        rules = FastlaneMetadataFilesWriter::MetadataRule.android_rules(version_name: '20.4', version_code: 1234)
        translations = downloader.class.parse_json_export(io: io) # Convert odd GlotPress JSON export format to standard Hash
        puts "Writing to #{locale_dir}..."
        FastlaneMetadataFilesWriter.write(locale_dir: locale_dir, translations: translations, rules: rules)
      end
    end
  end

  def demo_ios_metadata_loop
    downloader = Fastlane::Helper::GPDownloader.new(host: DOTORG, project: 'apps/ios/release-notes/')
    Locales.mag16.each do |locale|
      next unless Locale.valid?(locale, :appstore)
      downloader.download_locale(gp_locale: locale.glotpress, format: EXPORT_FMT::JSON) do |io|
        locale_dir = File.join(EXAMPLE_OUTPUT_DIR, 'fastlane', 'metadata', locale.appstore)
        rules = FastlaneMetadataFilesWriter::MetadataRule.ios_rules(version_name: '20.4')
        translations = downloader.class.parse_json_export(io: io) # Convert odd GlotPress JSON export format to standard Hash
        FastlaneMetadataFilesWriter.write(locale_dir: locale_dir, translations: translations, rules: rules)
      end
    end
  end
end
