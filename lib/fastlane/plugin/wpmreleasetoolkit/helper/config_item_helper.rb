# frozen_string_literal: true

module Fastlane
  module Helper
    class ConfigItemHelper
      OPT_IN_FAIL_ON_ERROR_CONFIG_ITEM_OPTIONS = {
        key: :fail_on_error,
        description: 'Whether handled errors should fail the lane instead of using the action-specific fallback behavior',
        type: FastlaneCore::Boolean,
        optional: true,
        default_value: false
      }.freeze
    end
  end
end
