require 'fastlane/action'
require_relative '../../helper/git_helper'
module Fastlane
  module Actions
    class CreateBranchAction < Action
      def self.run(params)
        branch_name = params[:branch_name]
        from = params[:from]

        Fastlane::Helper::GitHelper.create_branch(branch_name, from: from)
      end

      def self.description
        'Create a new branch named `branch_name`, cutting it from branch/commit/tag `from`'
      end

      def self.details
        'If the branch with that name already exists, it will instead switch to it and pull new commits.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :branch_name,
                                       env_name: 'BRANCH_NAME_TO_CREATE',
                                       description: 'The full name of the new branch to create, e.g. "release/1.2"',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :from,
                                       env_name: 'BRANCH_OR_COMMIT_TO_CUT_FROM',
                                       description: 'The branch/tag/commit from which to cut the branch from. If `nil`, will cut the new branch from the current commit. Otherwise, will checkout that commit/branch/tag before cutting the branch.',
                                       optional: true,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.authors
        ['Automattic']
      end
    end
  end
end
