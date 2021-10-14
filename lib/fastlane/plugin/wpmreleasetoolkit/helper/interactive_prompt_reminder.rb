require 'fastlane_core'

module FastlaneCore
  # NOTE: FastlaneCore::UI delegates to the FastlaneCore::Shell implementation when output is the terminal
  class Shell
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
    def self.with_reminder(after: [30, 180, 600], message: 'An interactive prompt is waiting for you in the Terminal!')
      delays_list = Array(after)
      thread = Thread.new do
        until delays_list.empty?
          sleep(delays_list.shift)
          $stdout.beep
          system('say', message)
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
    def self.monkey_patch_interactive_prompts_with_reminder
      %i[input confirm select password].each do |method_name|
        old_method = instance_method(method_name)

        define_method(method_name) do |*args|
          FastlaneCore::Shell.with_reminder { old_method.bind(self).call(*args) }
        end
      end
    end
  end
end

# Apply Monkey patch
FastlaneCore::Shell.monkey_patch_interactive_prompts_with_reminder
