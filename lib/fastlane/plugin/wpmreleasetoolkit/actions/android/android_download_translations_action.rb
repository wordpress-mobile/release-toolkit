# This action is the new version of android_update_metadata (AndroidUpdateMetadataAction) and should now be used instead of that one

module Fastlane
  module Actions
    class AndroidDownloadTranslationsAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_localize_helper.rb'
        require_relative '../../helper/git_helper.rb'

        res_dir = File.join(ENV['PROJECT_ROOT_FOLDER'] || '.', params[:res_dir])

        Fastlane::Helper::Android::LocalizeHelper.create_available_languages_file(
          res_dir: res_dir,
          locale_codes: [params[:source_locale]] + params[:locales].map { |h| h[:android] }
        )
        Fastlane::Helper::Android::LocalizeHelper.download_from_glotpress(
          res_dir: res_dir,
          glotpress_project_url: params[:glotpress_url],
          glotpress_filters: params[:status_filter].map { |s| { status: s } },
          locales_map: params[:locales]
        )

        # Update submodules then lint translations
        unless params[:lint_task].nil? || params[:lint_task].empty?
          Fastlane::Helper::GitHelper.update_submodules()
          Action.sh('./gradlew', params[:lint_task])
        end

        Fastlane::Helper::GitHelper.commit(message: 'Update translations', files: res_dir, push: true) unless params[:skip_commit]
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
            key: :res_dir,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_RES_DIR',
            description: "The path to the Android project's `res` dir (typically the `<project name>/src/main/res` directory) containing the `values-*` subdirs",
            type: String,
            default_value: "#{ENV['PROJECT_NAME']}/src/main/res"
          ),
          FastlaneCore::ConfigItem.new(
            key: :glotpress_url,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_GLOTPRESS_URL',
            description: 'URL to the GlotPress project',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :status_filter,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_STATUS_FILTER',
            description: 'The GlotPress status(es) to filter on when downloading the translations',
            type: Array,
            default_value: 'current'
          ),
          FastlaneCore::ConfigItem.new(
            key: :source_locale,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_SOURCE_LOCALE',
            description: 'The Android locale code for the source locale (the one serving as original/reference). This will be included into the `available_languages.xml` file',
            type: String,
            default_value: 'en_US'
          ),
          FastlaneCore::ConfigItem.new(
            key: :locales,
            description: 'An array of hashes – each with the :glotpress and :android keys – listing the locale codes to download and update',
            type: Array,
            verify_block: proc do |value|
              unless value.is_a?(Array) && value.all? { |e| e.is_a?(Hash) && e.has_key?(:glotpress) && e.has_key?(:android) }
                UI.user_error!('The value for the `locales` parameter must be an Array of Hashes, and each Hash must have at least `:glotpress` and `:android` keys.')
              end
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :lint_task,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_LINT_TASK',
            description: 'The name of the Gradle task to run to lint the translations (after this action have updated them). Set to nil or empty string to skip the lint',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :skip_commit,
            env_name: 'FL_DOWNLOAD_TRANSLATIONS_SKIP_COMMIT',
            description: 'If set to true, will skip the commit/push step. Otherwise, it will commit the changes and push them (the default)',
            is_string: false, # Boolean
            default_value: false
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
