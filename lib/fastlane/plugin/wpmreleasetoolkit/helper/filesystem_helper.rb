require 'fastlane_core/ui/ui'
require 'fileutils'
require 'digest'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class FilesystemHelper
      ### Traverse the file system to find the root project directory.
      ### For the purposes of this function, we're assuming the root project
      ### directory is the one with the `.git` file in it.
      def self.project_path

        continue = true
        dir = Pathname.new(Dir.pwd)

        while continue
          child_filenames = dir.children.map! { |x| File.basename(x) }

          if child_filenames.include? '.git'
            continue = false
          else
            dir = dir.parent
          end

          if dir.root?
            UI.user_error!("Unable to determine the project root directory – #{Dir.pwd} doesn't appear to reside within a git repository.")
          end
        end

        dir
      end

      def self.plugin_root

        continue = true
        dir = Pathname.new(__FILE__).dirname

        while continue
          child_filenames = dir.children.map! { |x| File.basename(x) }

          if child_filenames.include? 'fastlane-plugin-wpmreleasetoolkit.gemspec'
            continue = false
          else
            dir = dir.parent
          end

          if dir.root?
            UI.user_error!('Unable to determine the plugin root directory.')
          end
        end

        dir
      end

      ### Returns the path to the project's `.configure` file.
      def self.configure_file
        Pathname.new(project_path) + '.configure'
      end

      ### Returns the path to the project's `.configure-files` directory.
      def self.configure_files_dir
        Pathname.new(project_path) + '.configure-files'
      end

      def self.encrypted_file_path(file)
        File.join(configure_files_dir, "#{File.basename(file)}.enc")
      end

      ### Returns the path to the `~/.mobile-secrets` directory.
      def self.secret_store_dir
        return "#{Dir.home}/.mobile-secrets"
      end

      ### Transforms a relative path within the secret store to an absolute path on disk.
      def self.absolute_secret_store_path(relative_path)
        File.join(secret_store_dir, relative_path)
      end

      ### Path to keys.json in the secrets repository
      def self.secret_store_keys_path
        File.join(secret_store_dir, 'keys.json')
      end

      ### Transforms a relative path within the project to an absolute path on disk.
      def self.absolute_project_path(relative_path)
        File.join(project_path, relative_path)
      end

      ### Returns the `sha1` hash of a file, given the absolute path.
      def self.file_hash(absolute_path)

        unless File.file?(absolute_path)
          UI.user_error!("Unable to hash #{absolute_path} – the file does not exist")
        end

        Digest::SHA1.file absolute_path
      end
    end
  end
end
