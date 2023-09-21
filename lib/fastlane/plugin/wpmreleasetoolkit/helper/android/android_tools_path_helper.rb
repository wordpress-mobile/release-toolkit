require 'fastlane_core/ui/ui'

module Fastlane
  module Helper
    module Android
      # Helper to find the paths of common Android build and SDK tools on the current machine
      # Based on `$ANDROID_HOME` and the common relative paths those tools are installed in.
      #
      class ToolsPathHelper
        attr_reader :android_home

        def initialize(sdk_root: nil)
          @android_home = sdk_root || ENV['ANDROID_HOME'] || ENV['ANDROID_SDK_ROOT'] || ENV['ANDROID_SDK']
        end

        # @param [String] binary The name of the binary to search for
        # @param [Array<String>] search_paths The search paths, relative to `@android_home`, in which to search for the tools.
        #        If `android_home` is `nil` or the binary wasn't found in any of the `search_paths`, will fallback to searching in `$PATH`.
        # @return [String] The absolute path of the tool if found, `nil` if not found.
        def find_tool_path(binary:, search_paths:)
          bin_path = unless android_home.nil?
                       search_paths
                         .map { |path| File.join(android_home, path, binary) }
                         .find { |path| File.executable?(path) }
                     end

          # If not found in any of the `search_paths`, try to look for it in $PATH
          bin_path ||= Actions.sh('command', '-v', binary) { |err, res, _| res if err&.success? }&.chomp

          # Normalize return value to `nil` if it was not found, empty, or is not an executable
          bin_path = nil if !bin_path.nil? && (bin_path.empty? || !File.executable?(bin_path))

          bin_path
        end

        # @param [String] binary The name of the binary to search for
        # @param [Array<String>] search_paths The search paths, relative to `@android_home`, in which to search for the tools.
        #        If `android_home` is `nil` or the binary wasn't found in any of the `search_paths`, will fallback to searching in `$PATH`.
        # @return [String] The absolute path of the tool if found.
        # @raise [FastlaneCore::Interface::FastlaneError] If the tool couldn't be found.
        def find_tool_path!(binary:, search_paths:)
          bin_path = find_tool_path(binary:, search_paths:)
          UI.user_error!("Unable to find path for #{binary} in #{search_paths.inspect}. Verify you installed the proper Android tools.") if bin_path.nil?
          bin_path
        end

        def cmdline_tools_search_paths
          # It appears that depending on the machines and versions of Android SDK, some versions
          # installed the command line tools in `tools` and not `latest` subdirectory, hence why
          # we search both (`latest` first, `tools` as fallback) to cover all our bases.
          [
            File.join('cmdline-tools', 'latest', 'bin'),
            File.join('cmdline-tools', 'tools', 'bin'),
          ]
        end

        def sdkmanager
          @sdkmanager ||= find_tool_path!(
            binary: 'sdkmanager',
            search_paths: cmdline_tools_search_paths
          )
        end

        def avdmanager
          @avdmanager ||= find_tool_path!(
            binary: 'avdmanager',
            search_paths: cmdline_tools_search_paths
          )
        end

        def emulator
          @emulator ||= find_tool_path!(
            binary: 'emulator',
            search_paths: [File.join('emulator')]
          )
        end

        def adb
          @adb ||= find_tool_path!(
            binary: 'adb',
            search_paths: [File.join('platform-tools')]
          )
        end
      end
    end
  end
end
