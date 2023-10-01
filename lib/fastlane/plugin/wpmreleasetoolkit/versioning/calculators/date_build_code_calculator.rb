module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      # The `DateBuildCodeCalculator` class is a build code calculator for apps that use date-based
      # build codes.
      class DateBuildCodeCalculator
        # Calculate the next internal build code by setting the build number to the current date.
        #
        # @param [AppVersion] version The version to calculate the next internal version for.
        #
        # @return [AppVersion] The next version with the build number set to the current date.
        #
        def next_build_code(version:)
          new_version = version.dup
          new_version.build_number = today_date

          new_version
        end

        private

        # Get the current date in the format 'YYYYMMDD'.
        #
        # @return [String] The current date in 'YYYYMMDD' format.
        #
        def today_date
          DateTime.now.strftime('%Y%m%d')
        end
      end
    end
  end
end
