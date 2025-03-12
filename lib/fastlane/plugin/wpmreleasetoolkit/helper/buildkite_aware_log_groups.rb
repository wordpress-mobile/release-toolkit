# frozen_string_literal: true

require 'fastlane'

# This monkey-patch adds Buildkite-aware logs to fastlane so it generates a collapsible log group in Buildkite for each action execution.
#
# @env `FASTLANE_DISABLE_ACTIONS_BUILDKITE_LOG_GROUPS`
#     Set this variable to '1' to disable the auto-application of the monkey patch.

unless !ENV.key?('BUILDKITE') || FastlaneCore::Env.truthy?('FASTLANE_DISABLE_ACTIONS_BUILDKITE_LOG_GROUPS')
  FastlaneCore::UI.verbose('Monkey-patching fastlane to add Buildkite-aware log groups for each action execution')

  module Fastlane
    module Actions
      module SharedValues
        # This differs from the existing `SharedValues::LANE_NAME`, which always contains the name of the **top-level** lane
        CURRENTLY_RUNNING_LANE_NAME = :CURRENTLY_RUNNING_LANE_NAME
      end

      module BuildkiteLogActionsAsCollapsibleGroups
        def execute_action(action_name, &)
          unless %w[is_ci? is_ci].include?(action_name)
            current_lane = lane_context[SharedValues::CURRENTLY_RUNNING_LANE_NAME]
            lane_name_prefix = (current_lane || '').empty? ? '' : "[lane :#{current_lane}]"
            puts "~~~ :fastlane: #{lane_name_prefix} #{action_name}"
          end
          super
        end
      end

      class << self
        prepend BuildkiteLogActionsAsCollapsibleGroups
      end
    end

    class Runner
      prepend(Module.new do
        def current_lane=(lane_name)
          super
          Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::CURRENTLY_RUNNING_LANE_NAME] = lane_name
        end
      end)
    end
  end
end
