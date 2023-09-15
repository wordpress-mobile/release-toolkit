require_relative '../models/app_version'
require_relative 'version_formatter'

module Fastlane
  module Formatters
    class AndroidVersionFormatter < VersionFormatter
      BETA_IDENTIFIER = 'rc'.freeze

      def beta_version
        UI.user_error!('The build number of a beta version must be 1 or higher') unless @version.build_number.positive?

        "#{release_version}-#{BETA_IDENTIFIER}-#{@version.build_number}"
      end
    end
  end
end
