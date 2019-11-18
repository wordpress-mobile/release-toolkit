module Fastlane
    module Actions
      class AndroidCheckDevicesAction < Action
        def self.run(params)
          available_devices = other_action.adb_devices();
          if (params[:require_device] and available_devices.empty?)
            UI.user_error! "You need a device attached or an emulator running."
          end

          UI.message("Attached Devices:");
          available_devices.each do |device|
            UI.message(device.serial);
          end
          if available_devices.empty?
            "No Devices Found"
          else
            if (available_devices.count == 1)
              "One Device Found"
            else
              "#{available_devices.count} Devices Found"
            end
          end

        end
        #####################################################
        # @!group Documentation
        #####################################################
    
        def self.description
          "checks for attached devices"
        end
    
        def self.details
          "checks and prints a list of attached devices. can require a device to be attached."
        end

        def self.available_options
          [
            FastlaneCore::ConfigItem.new(key: :require_device,
                                         env_name: "FL_ANDROID_CHECK_DEVICES_REQUIRE_DEVICE", 
                                         description: "specify whether devices are required", 
                                         is_string: false,
                                         default_value: true)
          ]
        end
    
        def self.output
            
        end
    
        def self.return_value
            
        end
    
        def self.authors
          ["ravenstewart"]
        end
    
        def self.is_supported?(platform)
          platform == :android
        end
      end
    end
  end