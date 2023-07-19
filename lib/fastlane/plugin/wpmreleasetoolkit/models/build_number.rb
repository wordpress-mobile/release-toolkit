require 'xcodeproj'

module Fastlane
  module Model
    class BuildNumber
      attr_accessor :file_path, :build_number

      def initialize(file_path)
        @file_path = file_path
        @build_number = read_build_number_from_xcconfig

        puts 'Hello'
      end

      def read_build_number_from_xcconfig
        config = Xcodeproj::Config.new(@file_path)

        UI.user_error!('The .xcconfig file doesn\'t have a BUILD_NUMBER configured') if config.attributes['BUILD_NUMBER'].nil?

        config.attributes['BUILD_NUMBER']
      end

      def write_build_number_to_xcconfig
        if File.exist?(@file_path)
          new_build_number = bump_build_number(@build_number)
          Action.sh("sed -i '' \"$(awk '/^BUILD_NUMBER/{ print NR; exit }' \"#{@file_path}\")s/=.*/=#{new_build_number}/\" \"#{@file_path}\"")
        else
          UI.user_error!("#{@file_path} not found")
        end
      end

      def bump_build_number(build_number)
        build_number.nil? ? 0 : build_number.to_i + 1
      end
    end
  end
end
