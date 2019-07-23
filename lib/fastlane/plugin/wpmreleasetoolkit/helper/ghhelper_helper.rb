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

      def self.get_last_milestone(repository)
        options = {}
        options[:state]="open"

        milestones = GHClient().list_milestones(repository, options)
        if (milestones.nil?)
          return nil
        end

        last_stone = nil
        milestones.each do | mile |
          if (last_stone.nil?)
            last_stone = mile unless mile[:title].split(' ')[0].split('.').length < 2 
          else
            begin
              if (mile[:title].split(' ')[0].split('.')[0] > last_stone[:title].split(' ')[0].split('.')[0])
                last_stone = mile 
              else
                if (mile[:title].split(' ')[0].split('.')[1] > last_stone[:title].split(' ')[0].split('.')[1])
                  last_stone = mile 
                end
              end
            rescue
              puts "Found invalid milestone"
            end
          end
        end

        last_stone
      end

      def self.create_milestone(repository, newmilestone_number, newmilestone_duedate, need_submission)
        submission_date = need_submission ? newmilestone_duedate.to_datetime.next_day(11) : newmilestone_duedate.to_datetime.next_day(14)
        release_date = newmilestone_duedate.to_datetime.next_day(14)
        comment = "Code freeze: #{newmilestone_duedate.to_datetime.strftime("%B %d, %Y")} App Store submission: #{submission_date.strftime("%B %d, %Y")} Release: #{release_date.strftime("%B %d, %Y")}"

        options = {}
        options[:due_on] = newmilestone_duedate
        options[:description] = comment
        GHClient().create_milestone(repository, newmilestone_number, options)
      end

    end
  end
end
