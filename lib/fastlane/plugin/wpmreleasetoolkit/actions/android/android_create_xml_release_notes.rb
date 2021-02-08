module Fastlane
  module Actions
    class AndroidCreateXmlReleaseNotesAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_git_helper.rb'

        release_notes_path = params[:download_path] + "/release_notes.xml"
        open(release_notes_path, 'w') { |f|
          params[:locales].each do |loc|
            puts "Looking for language: #{loc[1]}"
            complete_path = "#{params[:download_path]}/#{loc[1]}/changelogs/#{params[:build_number]}.txt"
            if (File.exist?(complete_path))
              f.puts("<#{loc[1]}>")
              f.puts(File.open(complete_path).read)
              f.puts("</#{loc[1]}>\n")
            else
              UI.message("File #{complete_path} not found. Skipping language #{loc[1]}")
            end
          end
        }
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Downloads translated metadata from the translation system"
      end

      def self.details
        "Downloads translated metadata from the translation system"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :download_path,
                                        env_name: "ANDROID_XML_NOTES_DOWNLOAD_PATH",
                                     description: "The path to the folder with the release notes",
                                        optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :build_number,
                                        env_name: "ANDROID_XML_NOTES_BUILD_NUMBER",
                                     description: "The build number of the release notes",
                                        optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :locales,
                                        env_name: "FL_DOWNLOAD_METADATA_LOCALES",
                                        description: "The hash with the GLotPress locale and the project locale association",
                                        is_string: false),
        ]
      end

      def self.authors
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end