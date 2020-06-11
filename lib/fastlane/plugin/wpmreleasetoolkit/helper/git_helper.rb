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
    end
  end
end
