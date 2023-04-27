module Fastlane
  module Helper
    module ReleaseManagementInCIHelper
      def self.bump_version_beta_branch_name(new_version_beta)
        return "merge/#{new_version_beta}-to-release-branch"
      end
    end
  end
end
