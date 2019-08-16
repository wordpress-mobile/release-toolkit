require 'fastlane/action'
require 'fastlane_core/ui/ui'
require 'fileutils'
require 'json'

require_relative '../../helper/filesystem_helper'
require_relative '../../helper/configure_helper'

module Fastlane
  module Actions
    class ConfigureAddFilesToCopyAction < Action
      def self.run(params = {})

        continue = true

        while(continue)

          confirmation = "Do you want to specify a file that should be copied from the secrets repository into your project?"

          if Fastlane::Helper::ConfigureHelper.has_files
            confirmation = "Do you want to specify additional files that should be copied from the secrets repository into your project?"
          end

          if UI.confirm(confirmation)
            add_file
          else
            continue = false
          end

          Fastlane::Helper::ConfigureHelper.files_to_copy.each do |file_reference|
            file_reference.update
          end
        end
      end

      ### Walks the user through adding a file to the project's `/.configure `file.
      ###
      def self.add_file

        invalid_file = true

        while invalid_file
          UI.header "Please provide the location of the source file relative to the secrets repository"
          UI.message "Example: google-services.json"

          source = UI.input("Source File Path:")
          sourcePath = absolute_secret_store_path(source) # Transform the relative path into an absolute path.

          # Don't allow the developer to accidentally specify an invalid file, otherwise validation will never succeed.
          if File.file?(sourcePath)
            invalid_file = false
          else
            UI.error "There is no file at #{sourcePath}."
          end
        end

        UI.header "Please provide the destination of the file relative to the project root"
        UI.message "Example: WordPress/google-services.json"

        destination = UI.input("Destination File Path:") # Leave the destination as a relative path, as no validation is required.

        encrypt = UI.confirm("Encrypt file?:")

        Fastlane::Helper::ConfigureHelper.add_file(source: source, destination: destination, encrypt: encrypt)
      end

      def self.secret_store_dir
          Fastlane::Helper::FilesystemHelper.secret_store_dir
      end

      def self.absolute_secret_store_path(relative_path)
          Fastlane::Helper::FilesystemHelper.absolute_secret_store_path(relative_path)
      end

      def self.description
          "Interactively add files to the `files_to_copy` list in .configure."
      end

      def self.authors
          ["Jeremy Massel"]
      end

      def self.return_value
          # If your method provides a return value, you can describe here what it does
      end

      def self.details
          "Interactively add files to the `files_to_copy` list in .configure."
      end

      def self.available_options
          []
      end

      def self.is_supported?(platform)
          true
      end
    end
  end
end
