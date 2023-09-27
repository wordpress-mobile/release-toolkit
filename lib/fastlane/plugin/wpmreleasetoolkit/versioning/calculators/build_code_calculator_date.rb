module Fastlane
  module Wpmreleasetoolkit
    module Versioning
      class DateBuildCodeCalculator
        # Calculate the next internal build code by setting the build number to the current date.
        #
        # @param version [AppVersion] The version to calculate the next internal version for.
        #
        # @return [AppVersion] The next version with the build number set to the current date.
        #
        def next_build_code(version:)
          version.build_number = today_date

          version
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
