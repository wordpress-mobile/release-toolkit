# frozen_string_literal: true

module Fastlane
  module Helper
    class ConfigItemHelper
      def self.opt_in_fail_on_error_config_item
        FastlaneCore::ConfigItem.new(
          key: :fail_on_error,
          description: 'Whether handled errors should fail the lane instead of using the action-specific fallback behavior',
          type: FastlaneCore::Boolean,
          optional: true,
          default_value: false
        )
      end
    end
  end
end
