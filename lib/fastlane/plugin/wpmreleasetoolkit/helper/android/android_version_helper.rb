module Fastlane
    module Helpers
      module AndroidVersionHelper
        VERSION_NAME = "name"
        VERSION_CODE = "code"
        MAJOR_NUMBER = 0
        MINOR_NUMBER = 1
        HOTFIX_NUMBER = 2
        ALPHA_PREFIX = "alpha-"
        RC_SUFFIX = "-rc"
  
        def self.get_public_version
          version = get_release_version
          vp = get_version_parts(version[VERSION_NAME])
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}" unless is_hotfix(version)
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
        end

        def self.get_release_version
          section = ENV["HAS_ALPHA_VERSION"].nil? ? "defaultConfig" : "vanilla {"
          gradle_path = self.gradle_path
          name = get_version_name_from_file(gradle_path, section)
          code = get_version_build_from_file(gradle_path, section)
          return { VERSION_NAME => name, VERSION_CODE => code }
        end

        def self.get_alpha_version
          if (ENV["HAS_ALPHA_VERSION"].nil?)
            return nil
          end

          section = "defaultConfig"
          gradle_path = self.gradle_path
          name = get_version_name_from_file(gradle_path, section)
          code = get_version_build_from_file(gradle_path, section)
          return { VERSION_NAME => name, VERSION_CODE => code }
        end
  
        def self.is_alpha_version(version)
          version[VERSION_NAME].start_with?(ALPHA_PREFIX)
        end
  
        def self.is_beta_version(version)
          version[VERSION_NAME].include?(RC_SUFFIX)
        end
  
        def self.calc_final_release_version(beta_version, alpha_version)
          version_name = beta_version[VERSION_NAME].split('-')[0]
          version_code = alpha_version.nil? ? beta_version[VERSION_CODE] + 1 : alpha_version[VERSION_CODE] + 1 

          { VERSION_NAME => version_name, VERSION_CODE => version_code }
        end

        def self.calc_next_alpha_version(version, alpha_version)
          # Bump alpha name
          alpha_number = alpha_version[VERSION_NAME].sub(ALPHA_PREFIX, '')
          alpha_name = "#{ALPHA_PREFIX}#{alpha_number.to_i() + 1}"

          # Bump alpha code
          alpha_code = version[VERSION_CODE] + 1

          { VERSION_NAME => alpha_name, VERSION_CODE => alpha_code }
        end
  
        def self.calc_next_beta_version(version, alpha_version = nil)
          # Bump version name
          beta_number = is_beta_version(version) ? version[VERSION_NAME].split('-')[2].to_i + 1 : 1
          version_name = "#{version[VERSION_NAME].split('-')[0]}#{RC_SUFFIX}-#{beta_number}"

          # Bump version code
          version_code = alpha_version.nil? ? version[VERSION_CODE] + 1 : alpha_version[VERSION_CODE] + 1
          { VERSION_NAME => version_name, VERSION_CODE => version_code }
        end

        def self.calc_next_release_short_version(version)
          v = self.calc_next_release_base_version({ VERSION_NAME => version, VERSION_CODE => nil })
          return v[VERSION_NAME]
        end

        def self.calc_next_release_base_version(version)
          version_name = remove_beta_suffix(version[VERSION_NAME])
          vp = get_version_parts(version_name)
          vp[MINOR_NUMBER] += 1
          if (vp[MINOR_NUMBER] == 10)
            vp[MAJOR_NUMBER] += 1
            vp[MINOR_NUMBER] = 0
          end

          { VERSION_NAME => "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}", VERSION_CODE => version[VERSION_CODE] }
        end

        def self.calc_next_release_version(version, alpha_version = nil)
          nv = calc_next_release_base_version({ VERSION_NAME => version[VERSION_NAME], VERSION_CODE => alpha_version.nil? ? version[VERSION_CODE] : [version[VERSION_CODE], alpha_version[VERSION_CODE]].max})
          calc_next_beta_version(nv)
        end

        def self.calc_next_hotfix_version(hotfix_version_name, hotfix_version_code)
          { VERSION_NAME => hotfix_version_name, VERSION_CODE => hotfix_version_code}
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
  
        def self.is_hotfix(version)
          return false if is_alpha_version(version)
          vp = get_version_parts(version[VERSION_NAME])
          return (vp.length > 2) && (vp[HOTFIX_NUMBER] != 0)
        end
  
        def self.bump_version_release
          # Bump release
          current_version=get_release_version()
          UI.message("Current version: #{current_version[VERSION_NAME]}")
          new_version=calc_next_release_base_version(current_version)
          UI.message("New version: #{new_version[VERSION_NAME]}")
          verified_version=verify_version(new_version[VERSION_NAME])

          return verified_version
        end

        def self.update_versions(new_version_beta, new_version_alpha)
          self.update_version(new_version_beta, ENV["HAS_ALPHA_VERSION"].nil? ? "defaultConfig" : "vanilla {")
          self.update_version(new_version_alpha, "defaultConfig") unless new_version_alpha.nil?
        end

        def self.calc_prev_hotfix_version_name(version_name)
          vp = get_version_parts(version_name)
          vp[HOTFIX_NUMBER] -= 1 unless vp[HOTFIX_NUMBER] == 0
          return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}" unless vp[HOTFIX_NUMBER] == 0
          "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
        end

        # private 
        def self.remove_beta_suffix(version)
          version.split('-')[0]
        end

        def self.get_version_parts(version)
          version.split(".").fill("0", version.length...3).map{|chr| chr.to_i}
        end
  
        def self.get_version_name_from_file(file_path, section)
          res = get_data_from_file(file_path, section, "versionName")
          res = res.split(' ')[1].tr('\"', '') unless res.nil?
          return res
        end
  
        def self.get_version_build_from_file(file_path, section)
          res = get_data_from_file(file_path, section, "versionCode")
          res = res.split(' ')[1].to_i
          return res
        end

        # FIXME: This implementation is very fragile. This should be done parsing the file in a proper way. 
        # Leveraging gradle itself is probably the easiest way.
        def self.get_data_from_file(file_path, section, keyword)
          found_section = false
          File.open(file_path, 'r') do |file|
            file.each_line do |line|
              if !found_section
                if (line.include? section) 
                  found_section = true
                end
              else
                if (line.include? keyword)
                  return line unless line.include?("\"#{keyword}\"") or line.include?("P#{keyword}")
                end
              end
            end
          end
          return nil
        end

        def self.verify_version(version)
          v_parts = get_version_parts(version)
          
          v_parts.each do | part |
            if (!is_number?(part)) then
              UI.user_error!("Version value can only contains numbers.")
            end
          end

          "#{v_parts[MAJOR_NUMBER]}.#{v_parts[MINOR_NUMBER]}"
        end

        def self.is_number? string
          true if Float(string) rescue false
        end

        def self.gradle_path 
          "#{ENV["PROJECT_ROOT_FOLDER"]}#{ENV["PROJECT_NAME"]}/build.gradle"
        end

        # FIXME: This implementation is very fragile. This should be done parsing the file in a proper way. 
        # Leveraging gradle itself is probably the easiest way.
        def self.update_version(version, section)
          gradle_path = self.gradle_path
          temp_file = Tempfile.new('fastlaneIncrementVersion')
          found_section = false
          version_updated = 0
          File.open(gradle_path, 'r') do |file|
            file.each_line do |line|
              if !found_section
                temp_file.puts line
                if (line.include? section) 
                  found_section = true
                end
              else
                if (version_updated < 2)
                  if (line.include? "versionName") and (!line.include? "\"versionName\"") and (!line.include?"PversionName")
                    version_name = line.split(' ')[1].tr('\"', '')
                    line.replace line.sub(version_name, version[VERSION_NAME].to_s)
                    version_updated = version_updated + 1
                  end

                  if (line.include? "versionCode")
                    version_code = line.split(' ')[1]
                    line.replace line.sub(version_code, version[VERSION_CODE].to_s)
                    version_updated = version_updated + 1
                  end
                end
                temp_file.puts line
              end
            end
            file.close
          end
          temp_file.rewind
          temp_file.close
          FileUtils.mv(temp_file.path, gradle_path)
          temp_file.unlink
        end
      end
    end
  end