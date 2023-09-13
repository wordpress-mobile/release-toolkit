require_relative '../models/app_version'
require_relative 'version_formatter'

module Fastlane
  module Formatters
    class AndroidVersionFormatter < VersionFormatter
      def beta_version
        "#{release_version}-rc-#{build_number}"
      end
    end
  end
end
