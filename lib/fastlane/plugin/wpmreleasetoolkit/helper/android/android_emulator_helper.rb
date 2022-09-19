module Fastlane
  module Helper
    module Android
      # Helper methods to manipulate System Images, AVDs and Android Emulators
      #
      class EmulatorHelper
        BOOT_WAIT = 2
        BOOT_TIMEOUT = 60

        SHUTDOWN_WAIT = 2
        SHUTDOWN_TIMEOUT = 60

        def initialize
          @tools = Fastlane::Helper::Android::ToolsPathHelper.new
        end

        # Installs the system-image suitable for a given Android `api`, with `google_apis`, and for the current machine's architecture
        #
        # @param [Integer] api The Android API level to use
        #
        # @return [String] The `sdkmanager` package specifier that has been installed
        #
        def install_system_image(api:)
          package = system_image_package(api: api)

          UI.message("Installing System Image for Android #{api} (#{package})")
          Actions.sh(@tools.sdkmanager, '--install', package)
          UI.success("System Image #{package} successfully installed.")
          package
        end

        # Create an emulator (AVD) for a given `api` number and `device` model
        #
        # @param [Integer] api The Android API level to use for this AVD
        # @param [String] device The Device Model to use for this AVD. Valid values can be found using `avdmanager list devices`
        # @param [String] name The name to give for the created AVD. Defaults to `<device>_API_<api>`.
        # @param [String] sdcard The size of the SD card for this device. Defaults to `512M`.
        #
        # @return [String] The device name (i.e. either `name` if provided, or the derived `<device>_API_<api>` if provided `name` was `nil``)
        #
        def create_avd(api:, device:, system_image: nil, name: nil, sdcard: '512M')
          package = system_image || system_image_package(api: api)
          device_name = name || "#{device.gsub(' ', '_').capitalize}_API_#{api}"

          UI.message("Creating AVD `#{device_name}` (#{device}, API #{api})")

          Actions.sh(
            @tools.avdmanager, 'create', 'avd',
            '--force',
            '--package', package,
            '--device', device,
            '--sdcard', sdcard,
            '--name', device_name
          )

          UI.success("AVD `#{device_name}` successfully created.")

          device_name
        end

        # Launch the emulator for the given AVD, then return the emulator serial
        #
        # @param [String] name name of the AVD to launch
        # @param [Int] port the TCP port to use to connect to the emulator via adb. If nil (default), will let `emulator` pick the first free one.
        # @param [Boolean] cold_boot if true, will do a cold boot, if false will try to use a previous snapshot of the device
        # @param [Boolean] wipe_data if true, will wipe the emulator (i.e. reset the user data image)
        #
        # @return [String] emulator serial number corresponding to the launched AVD
        #
        def launch_avd(name:, port: nil, cold_boot: true, wipe_data: true)
          UI.message("Launching emulator for #{name}")

          params = ['-avd', name]
          params << ['-port', port.to_s] unless port.nil?
          params << '-no-snapshot' if cold_boot
          params << '-wipe-data' if wipe_data

          UI.command([@tools.emulator, *params].shelljoin)
          # We want to launch emulator in the background to not block the rest of the code, so we can't use `Actions.sh` here
          # We also want to filter the `stdout`+`stderr` emitted by the `emulator` process in the background,
          # to limit verbosity and only print error lines, and also prefix those clearly (because they might happen
          # at any moment in the background, so in parallel/the middle of other fastlane logs).
          t = Thread.new do
            Open3.popen2e(@tools.emulator, *params) do |i, oe, wait_thr|
              i.close
              until oe.eof?
                line = oe.readline
                UI.error("📱 [emulator]: #{line}") if line.start_with?(/ERROR|PANIC/)
                next unless line.include?('PANIC: Broken AVD system path')

                UI.user_error! <<~HINT
                  #{line}
                  Verify that your `sdkmanager/avdmanager` tools are not installed in a different SDK root than your `emulator` tool
                  (which can happen if you installed Android's command-line tools via `brew`, but the `emulator` via Android Studio, or vice-versa)
                HINT
              end
              UI.error("📱 [emulator]: exited with non-zero status code: #{wait_thr.value.exitstatus}") unless wait_thr.value.success?
            end
          end
          t.abort_on_exception = true # To bubble up any exception like `UI.user_error!` back to the main thread here

          UI.message('Waiting for emulator to start...')
          # Loop until the emulator has started and shows up in `adb devices -l` so we can find its serial
          serial = nil
          retry_loop(time_between_retries: BOOT_WAIT, timeout: BOOT_TIMEOUT, description: 'waiting for emulator to start') do
            serial = find_serial(avd_name: name)
            !serial.nil?
          end
          UI.message("Found device `#{name}` with serial `#{serial}`")

          # Once the emulator has started, wait for the device in the emulator to finish booting
          UI.message('Waiting for device to finish booting...')
          retry_loop(time_between_retries: BOOT_WAIT, timeout: BOOT_TIMEOUT, description: 'waiting for device to finish booting') do
            Actions.sh(@tools.adb, '-s', serial, 'shell', 'getprop', 'sys.boot_completed').chomp == '1'
          end

          UI.success("Emulator #{name} successfully booted as `#{serial}`.")

          serial
        end

        # @return [Array<Fastlane::Helper::AdbDevice>] List of currently booted emulators
        #
        def running_emulators
          helper = Fastlane::Helper::AdbHelper.new(adb_path: @tools.adb)
          helper.load_all_devices.select { |device| device.serial.include?('emulator') }
        end

        def find_serial(avd_name:)
          running_emulators.find do |candidate|
            command = [@tools.adb, '-s', candidate.serial, 'emu', 'avd', 'name']
            UI.command(command.shelljoin)
            candidate_name = Actions.sh(*command, log: false).split("\n").first.chomp
            candidate_name == avd_name
          end&.serial
        end

        # Trigger a shutdown for all running emulators, and wait until there is no more emulators running.
        #
        # @param [Array<String>] serials List of emulator serials to shut down. Will shut down all of them if `nil`.
        #
        def shut_down_emulators!(serials: nil)
          UI.message("Shutting down #{serials || 'all'} emulator(s)...")

          emulators_list = running_emulators.map(&:serial)
          # Get the intersection of the set of running emulators with the ones we want to shut down
          emulators_list &= serials unless serials.nil?
          emulators_list.each do |e|
            Actions.sh(@tools.adb, '-s', e, 'emu', 'kill') { |_| } # ignore error if no emulator with specified serial is running

            # NOTE: Alternative way of shutting down emulator would be to call the following command instead, which shuts down the emulator more gracefully:
            # `adb -s #{e} shell reboot -p` # In case you're wondering, `-p` is for "power-off"
            # But this alternate command:
            #  - Requires that `-no-snapshot` was used on boot (to avoid being prompted to save current state on shutdown)
            #  - Disconnects the emulator from `adb` (and thus disappear from `adb devices -l`) for a short amount of time,
            #    before reconnecting to it but in an `offline` state, until `emulator` finally completely quits and it disappears
            #    again (for good) from `adb devices --list`.
            # This means that so if we used alternative, we couldn't really retry_loop until emulator disappears from `running_emulators` to detect
            # that the shutdown was really complete, as we might as well accidentally detect the intermediate disconnect instead.
          end

          # Wait until all emulators are killed
          retry_loop(time_between_retries: SHUTDOWN_WAIT, timeout: SHUTDOWN_TIMEOUT, description: 'waiting for devices to shutdown') do
            (emulators_list & running_emulators.map(&:serial)).empty?
          end

          UI.success('All emulators are now shut down.')
        end

        # Find the system-images package for the provided API, with Google APIs, and matching the current platform/architecture this lane is called from.
        #
        # @param [Integer] api The Android API level to use for this AVD
        # @return [String] The `system-images;android-<N>;google_apis;<platform>` package specifier for `sdkmanager` to use in its install command
        #
        # @note Results from this method are memoized, to avoid repeating calls to `sdkmanager` when querying for the same api level multiple times.
        #
        def system_image_package(api:)
          @system_image_packages ||= {}
          @system_image_packages[api] ||= begin
            platform = `uname -m`.chomp
            all_packages = `#{@tools.sdkmanager} --sdk_root=#{@tools.android_sdk_root} --list`
            package = all_packages.match(/^ *(system-images;android-#{api};google_apis;#{platform}(-[^ ]*)?)/)&.captures&.first
            UI.user_error!("Could not find system-image for API `#{api}` and your platform `#{platform}` in `sdkmanager --list`. Maybe Google removed it for download and it's time to update to a newer API?") if package.nil?
            package
          end
        end

        def retry_loop(time_between_retries:, timeout:, description:)
          Timeout.timeout(timeout) do
            sleep(time_between_retries) until yield
          end
        rescue Timeout::Error
          UI.user_error!("Timed out #{description}")
        end
      end
    end
  end
end
