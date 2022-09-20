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

        def tool(binary:, search_paths:)
          bin_path = `command -v #{binary}`.chomp

          return bin_path unless bin_path.nil? || bin_path.empty? || !File.executable?(bin_path)

          bin_path = search_paths
                     .map { |path| File.join(android_home, path, binary) }
                     .find { |path| File.executable?(path) }

          UI.user_error!("Unable to find path for #{binary} in #{search_paths.inspect}. Verify you installed the proper Android tools.") if bin_path.nil?
          bin_path
        end

        def sdkmanager
          @sdkmanager ||= tool(
            binary: 'sdkmanager',
            search_paths: [File.join('cmdline-tools', 'latest', 'bin')]
          )
        end

        def avdmanager
          @avdmanager ||= tool(
            binary: 'avdmanager',
            search_paths: [File.join('cmdline-tools', 'latest', 'bin')]
          )
        end

        def emulator
          @emulator ||= tool(
            binary: 'emulator',
            search_paths: [File.join('emulator')]
          )
        end

        def adb
          @adb ||= tool(
            binary: 'adb',
            search_paths: [File.join('platform-tools')]
          )
        end
      end
    end
  end
end
