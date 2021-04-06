# This action is the new version of android_update_metadata (AndroidUpdateMetadataAction) and should now be used instead of that one

module Fastlane
  module Actions
    class AndroidDownloadTranslationsAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_localize_helper.rb'
        require_relative '../../helper/git_helper.rb'

        res_dir = File.join(ENV['PROJECT_ROOT_FOLDER'] || '.', params[:project_dir_name], 'src', 'main', 'res')

        Fastlane::Helper::Android::LocalizeHelper.create_available_languages_file(
          res_dir: res_dir,
          locale_codes: [params[:source_locale]] + params[:locales].map { |h| h[:android] }
        )
        Fastlane::Helper::Android::LocalizeHelper.download_from_glotpress(
          res_dir: res_dir,
          glotpress_project_url: params[:glotpress_url],
          locales_map: params[:locales]
        )

        # Update submodules then lint translations
        Fastlane::Helper::GitHelper.update_submodules()
        Action.sh('./gradlew', params[:lint_task])

        Fastlane::Helper::GitHelper.commit(message: 'Update translations', files: res_dir, push: true)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Download Android string.xml files from GlotPress and lint the updated translations'
      end

      def self.details
        'Download translations from GlotPress, update local strings.xml files accordingly, lint, commit the changes, and push to the remote'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :project_dir_name,
            env_name: 'PROJECT_NAME',
            description: 'The name of the Android project (i.e. the name of the parent folder containing `src/main/res`)',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :glotpress_url,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_GLOTPRESS_URL',
            description: 'URL to the GlotPress project',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :source_locale,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_SOURCE_LOCALE',
            description: 'The Android locale code for the source locale (the one serving as original/reference)',
            type: String,
            default_value: 'en_US'
          ),
          FastlaneCore::ConfigItem.new(
            key: :locales,
            description: 'An array of hashes – each with the :glotpress and :android keys – listing the locale codes to download and update',
            type: Array
          ),
          FastlaneCore::ConfigItem.new(
            key: :lint_task,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_LINT_TASK',
            description: 'The name of the Gradle task to run to lint the translations (after this action have updated them)',
            type: String,
            default_value: 'lintVanillaRelease'
          ),
        ]
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ['AliSoftware']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
