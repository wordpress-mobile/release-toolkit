module Fastlane
    module Helpers
      module IosVersionHelper
        MAJOR_NUMBER = 0
        MINOR_NUMBER = 1
        HOTFIX_NUMBER = 2
        BUILD_NUMBER = 3
  
        def self.get_public_version
          version = get_build_version
          vp = get_version_parts(version)
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}" unless is_hotfix(version)
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end
  
        def self.calc_next_release_version(version)
          vp = get_version_parts(version)
          vp[MINOR_NUMBER] += 1
          if (vp[MINOR_NUMBER] == 10)
            vp[MAJOR_NUMBER] += 1
            vp[MINOR_NUMBER] = 0
          end
  
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end
  
        def self.get_short_version_string(version)
          vp = get_version_parts(version)
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        def self.calc_prev_release_version(version)
          vp = get_version_parts(version)
          if (vp[MINOR_NUMBER] == 0)
            vp[MAJOR_NUMBER] -= 1
            vp[MINOR_NUMBER] = 9
          else
            vp[MINOR_NUMBER] -= 1
          end
          
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end
  
        def self.calc_next_build_version(version)
          vp = get_version_parts(version)
          vp[BUILD_NUMBER] += 1
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{vp[BUILD_NUMBER]}"
        end
  
        def self.calc_next_hotfix_version(version)
          vp = get_version_parts(version)
          vp[HOTFIX_NUMBER] += 1
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end
  
        def self.calc_prev_build_version(version)
          vp = get_version_parts(version)
          vp[BUILD_NUMBER] -= 1 unless vp[BUILD_NUMBER] == 0
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{vp[BUILD_NUMBER]}"
        end
  
        def self.calc_prev_hotfix_version(version)
          vp = get_version_parts(version)
          vp[HOTFIX_NUMBER] -= 1 unless vp[HOTFIX_NUMBER] == 0
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}" unless vp[HOTFIX_NUMBER] == 0
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        def self.create_internal_version(version)
          vp = get_version_parts(version)
          d = DateTime.now
          todayDate = d.strftime("%Y%m%d")
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{todayDate}"
        end
  
        def self.bump_build_number(build_number)
          build_number.nil? ? 0 : build_number.to_i + 1
        end

        def self.is_hotfix(version)
          vp = get_version_parts(version)
          return (vp.length > 2) && (vp[HOTFIX_NUMBER] != 0)
        end
  
        def self.get_build_version
          versions = get_version_strings()[0]
        end
  
        def self.get_internal_version
          get_version_strings()[1]
        end
  
        def self.bump_version_release
          # Bump release
          current_version=get_public_version()
          UI.message("Current version: #{current_version}")
          new_version=calc_next_release_version(current_version)
          UI.message("New version: #{new_version}")
          verified_version=verify_version(new_version)

          return verified_version
        end

        def self.update_fastlane_deliver(new_version)
          fd_file = "./fastlane/Deliverfile"
          if (File.exist?(fd_file)) then
            Action.sh("sed -i '' \"s/app_version.*/app_version \\\"#{new_version}\\\"/\" #{fd_file}")
          else
            UI.user_error!("Can't find #{fd_file}.")
          end
        end

        def self.update_xc_configs(new_version, new_version_short, internal_version)
          update_xc_config(ENV["PUBLIC_CONFIG_FILE"], new_version, new_version_short) 
          update_xc_config(ENV["INTERNAL_CONFIG_FILE"], internal_version, new_version_short) unless ENV["INTERNAL_CONFIG_FILE"].nil?
        end

        def self.update_xc_config(file_path, new_version, new_version_short)
          if File.exist?(file_path) then
            UI.message("Updating #{file_path} to version #{new_version_short}/#{new_version}")
            Action.sh("sed -i '' \"$(awk '/^VERSION_SHORT/{ print NR; exit }' \"#{file_path}\")s/=.*/=#{new_version_short}/\" \"#{file_path}\"") 
            Action.sh("sed -i '' \"$(awk '/^VERSION_LONG/{ print NR; exit }' \"#{file_path}\")s/=.*/=#{new_version}/\" \"#{file_path}\"")

            build_number = read_build_number_from_config_file(file_path)
            unless (build_number.nil?)
              new_build_number = bump_build_number(build_number)
              Action.sh("sed -i '' \"$(awk '/^BUILD_NUMBER/{ print NR; exit }' \"#{file_path}\")s/=.*/=#{new_build_number}/\" \"#{file_path}\"")
            end
          else
            UI.user_error!("#{file_path} not found")
          end
        end

        private 
  
        def self.get_version_parts(version)
          parts=version.split(".")
          parts=parts.fill("0", parts.length...4).map{|chr| chr.to_i}
          if (parts.length > 4) then        
            UI.user_error!("Bad version string: #{version}")
          end

          return parts
        end
  
        def self.read_long_version_from_config_file(filePath)
          read_from_config_file("VERSION_LONG", filePath)
        end

        def self.read_build_number_from_config_file(filePath)
          read_from_config_file("BUILD_NUMBER", filePath)
        end

        def self.read_from_config_file(key, filePath)
          File.open(filePath, "r") do |f|
            f.each_line do |line|
              line = line.strip()
              if line.start_with?("#{key}=") then
                  return line.split("=")[1]
                end
              end
          end

          return nil
        end

        def self.get_version_strings
          version_strings = Array.new
          version_strings << read_long_version_from_config_file(ENV["PUBLIC_CONFIG_FILE"])
          version_strings << read_long_version_from_config_file(ENV["INTERNAL_CONFIG_FILE"]) unless ENV["INTERNAL_CONFIG_FILE"].nil?

          return version_strings
        end

        def self.verify_version(version)
          v_parts = get_version_parts(version)
          
          v_parts.each do | part |
            if (!is_number?(part)) then
              UI.user_error!("Version value can only contains numbers.")
            end
          end

          "#{v_parts[MAJOR_NUMBER]}.#{v_parts[MINOR_NUMBER]}.#{v_parts[HOTFIX_NUMBER]}.#{v_parts[BUILD_NUMBER]}"
        end

        def self.is_number? string
          true if Float(string) rescue false
        end
      end
    end
  end