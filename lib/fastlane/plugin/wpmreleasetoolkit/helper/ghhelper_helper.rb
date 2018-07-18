require 'fastlane_core/ui/ui'
require 'octokit'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class GhhelperHelper
      def self.GHClient()
        client = Octokit::Client.new(:access_token => ENV["GHHELPER_ACCESS"])

        # Fetch the current user
        user = client.user
        UI.message("Logged in as: #{user.name}")

        client
      end

      def self.get_milestone(repository, release)
        miles = GHClient().list_milestones(repository)
        mile = nil
      
        miles&.each do |mm| 
          if mm[:title].start_with?(release)
            mile = mm
          end
        end
  
        return mile
      end
    end
  end
end
