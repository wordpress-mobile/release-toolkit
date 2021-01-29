require 'git'

module Fastlane
  module Helper
    module GitHelper

      def self.is_git_repo
        system "git rev-parse --git-dir 1> /dev/null 2>/dev/null"
      end

      def self.has_git_lfs
        return false unless is_git_repo
        `git config --get-regex lfs`.length > 0
      end

      # `git add` the specified files (if any provided) then commit them using the provided message.
      # Optionally, push the commit to the remote too.
      #
      # @param [String] message The commit message to use
      # @param [String|Array<String>] files A file or array of files to git-add before creating the commit.
      #        use `nil` or `[]` if you already added the files in a separate step and don't wan't this method to add any new file before commit.
      #        Also accepts the special symbol `:all` to add all the files (`git commit -a -m …`).
      # @param [Bool] push If true, will `git push` to `origin` after the commit has been created. Defaults to `false`.
      #
      def self.commit(message:, files: nil, push: false)
        files = [files] if files.is_a?(String)
        args = []
        if files  == :all
          args = ['-a']
        elsif !files.nil? && !files.empty?
          Action.sh("git", "add", *files)
        end
        Action.sh("git", "commit", *args, "-m", message)
        Action.sh("git", "push", "origin", "HEAD") if push
      end
    end
  end
end
