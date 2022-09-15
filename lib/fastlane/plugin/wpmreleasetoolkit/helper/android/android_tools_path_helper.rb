require 'fastlane_core/ui/ui'

module Fastlane
  module Helper
    module Android
      # Helper to find the paths of common Android build and SDK tools on the current machine
      # Based on `$ANDROID_SDK_ROOT` and the common relative paths those tools are installed in.
      #
      class ToolsPathHelper
        attr_reader :android_sdk_root

        def initialize(sdk_root: nil)
          @android_sdk_root = sdk_root || ENV['ANDROID_HOME'] || ENV['ANDROID_SDK_ROOT'] || ENV['ANDROID_SDK']
        end

        def tool(paths:, binary:)
          bin_path = `command -v #{binary}`.chomp
          return bin_path unless bin_path.nil? || bin_path.empty? || !File.executable?(bin_path)

          bin_path = paths
                     .map { |path| File.join(android_sdk_root, path, binary) }
                     .first { |path| File.executable?(path) }

          UI.user_error!("Unable to find path for #{binary} in #{paths.inspect}. Verify you installed the proper Android tools.") if bin_path.nil?
          bin_path
        end

        def sdkmanager
          @sdkmanager ||= tool(paths: %w[cmdline-tools latest bin], binary: 'sdkmanager')
        end

        def avdmanager
          @avdmanager ||= tool(paths: %w[cmdline-tools latest bin], binary: 'avdmanager')
        end

        def emulator
          @emulator ||= tool(paths: ['emulator'], binary: 'emulator')
        end

        def adb
          @adb ||= tool(paths: ['platform-tools'], binary: 'adb')
        end
      end
    end
  end
end
