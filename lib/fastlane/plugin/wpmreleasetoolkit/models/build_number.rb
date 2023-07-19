require 'xcodeproj'

module Fastlane
  module Model
    class BuildNumber
      attr_accessor :file_path

      def initialize(file_path)
        @file_path = file_path
      end

      def get_build_number
        read_build_number_from_xcconfig.to_s
      end

      def read_build_number_from_xcconfig
        config = Xcodeproj::Config.new(@file_path)

        UI.user_error!('The .xcconfig file doesn\'t have a BUILD_NUMBER configured') if config.attributes['BUILD_NUMBER'].nil?

        config.attributes['BUILD_NUMBER']
      end

      def write_build_number_to_xcconfig(build_number)
        if File.exist?(@file_path)
          Action.sh("sed -i '' \"$(awk '/^BUILD_NUMBER/{ print NR; exit }' \"#{@file_path}\")s/=.*/=#{build_number}/\" \"#{@file_path}\"")
        else
          UI.user_error!("#{@file_path} not found")
        end
      end

      def bump_build_number
        new_build_number = get_build_number.nil? ? 0 : build_number.to_i + 1
        write_build_number_to_xcconfig(new_build_number)
      end
    end
  end
end
