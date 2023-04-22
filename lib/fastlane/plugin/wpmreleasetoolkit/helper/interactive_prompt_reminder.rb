require 'fastlane_core'

# The features in this file are controlled by the following ENV vars:
#
# @env `FASTLANE_PROMPT_REMINDER_DISABLE_AUTO_PATCH`
#     If this variable is set, it will disable the auto-application of the monkey patch. In such case,
#     `UI.input`, `UI.confirm`, `UI.select` and `UI.password` methods won't be automatically patched
#     unless you explicitly call `monkey_patch_interactive_prompts_with_reminder` yourself.
#
# @env `FASTLANE_PROMPT_REMINDER_MESSAGE`
#     - If not set, then while auto-patching the `UI.…` methods, it will NOT make the patched methods
#       speak any vocal message – and instead will only emit a beep and make your Terminal icon jump in the Dock.
#     - If set to `default`, `true`, `yes` or `1`, then while auto-patching the `UI.…` methods, it will
#       make the patched methods announce the default message.
#     - If set to any other string, it will make the patched methods use that string as the message to announce
#       during the reminders
#     - NOTE: This env var only has an effect if the other `FASTLANE_PROMPT_REMINDER_DISABLE_AUTO_PATCH` env var
#       is _not_ set (and thus the `UI.…` methods _are_ auto-patched), because it only affects how auto-patching is done.
#
# @env `FASTLANE_PROMPT_REMINDER_DELAYS`
#     The delays (in seconds) to use when monkey-patching the `UI.…` methods to wrap them around `with_reminder`,
#     separated by a comma (e.g. `60,300,900`). If unset, will use the default delays of `30,180,600`.

module FastlaneCore
  # NOTE: FastlaneCore::UI delegates to the FastlaneCore::Shell implementation when output is the terminal
  class Shell
    DEFAULT_PROMPT_REMINDER_MESSAGE = 'An interactive prompt is waiting for you in the Terminal!'.freeze
    DEFAULT_PROMPT_REMINDER_DELAYS = [30, 180, 600].freeze

    # Calls the block given and remind the user with a vocal message if the block does not return after specific delays.
    #
    # Especially useful when using a block which calls methods that are interactive, in order to remind the user
    # to answer the interactive prompt if they forgot about it after some delays.
    #
    # Example usage:
    #
    #       text = with_reminder do
    #         puts "Enter some text:"
    #         $stdout.getch
    #       end
    #
    # @param [Double,Array<Double>] after
    #        Delay or list of delays to wait for before pronouncing the reminder message.
    #        If an array of values is passed, the message will be pronounced multiple times, after having waited for the subsequent delays in turn.
    #        Defaults to reminding after 30s, then 3mn, then 10mn.
    # @param [String] message
    #        The message to pronounce out loud after the delay has passed, if the block hasn't returned beforehand.
    # @return The same value that the blocks might return
    #
    def self.with_reminder(after: DEFAULT_PROMPT_REMINDER_DELAYS, message: DEFAULT_PROMPT_REMINDER_MESSAGE)
      delays_list = Array(after.dup)
      thread = Thread.new do
        until delays_list.empty?
          sleep(delays_list.shift)
          $stdout.beep
          system('say', message) unless message.nil?
        end
      end
      # execute the interactive code
      res = yield
      # if we replied before the timeout, kill the thread so message won't be triggered
      thread.kill
      # If the block given returned a value, pass it
      return res
    end

    # Monkey-Patch fastlane's `UI.input`, `UI.confirm`, `UI.select` and `UI.password` interactive methods
    # (which delegate to `FastlaneCore::Shell` when output is the terminal)
    #
    # Once you call this method, any invocation of `UI.input`, `UI.confirm`, `UI.select` or `UI.password`
    # anywhere in Fastlane (by your Fastfile, an action, …) will be wrapped in a call to with_reminder automatically.
    #
    def self.monkey_patch_interactive_prompts_with_reminder(after: DEFAULT_PROMPT_REMINDER_DELAYS, message: DEFAULT_PROMPT_REMINDER_MESSAGE)
      %i[input confirm select password].each do |method_name|
        old_method = instance_method(method_name)

        define_method(method_name) do |*args|
          FastlaneCore::Shell.with_reminder(after: after, message: message) { old_method.bind(self).call(*args) }
        end
      end
    end
  end
end

# Apply Monkey patch
unless ENV['FASTLANE_PROMPT_REMINDER_DISABLE_AUTO_PATCH']
  message = ENV.fetch('FASTLANE_PROMPT_REMINDER_MESSAGE', nil)
  message = FastlaneCore::Shell::DEFAULT_PROMPT_REMINDER_MESSAGE if %w[default true yes 1].include?(message&.downcase)
  delays = ENV['FASTLANE_PROMPT_REMINDER_DELAYS']&.split(',')&.map(&:to_i) || FastlaneCore::Shell::DEFAULT_PROMPT_REMINDER_DELAYS

  FastlaneCore::UI.verbose("Monkey-patching the UI interactive methods to add a reminder (#{delays.inspect}, #{message.inspect})")
  FastlaneCore::Shell.monkey_patch_interactive_prompts_with_reminder(after: delays, message: message)
end
