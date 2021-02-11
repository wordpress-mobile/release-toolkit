module Fastlane
  module Actions
    class AddAllDevicesToProvisioningProfilesAction < Action
      def self.run(params)
        require 'spaceship'

        Spaceship.login
        Spaceship.select_team(team_id: params[:team_id])

        devices = Spaceship.device.all_ios_profile_devices

        params[:app_identifier].each { |identifier|
          Spaceship.provisioning_profile.find_by_bundle_id(bundle_id: identifier)
                   .select { |profile|
              profile.kind_of? Spaceship::Portal::ProvisioningProfile::Development
          }
                   .tap { |profiles|
              UI.important "Warning: Unable to find any profiles associated with #{identifier}" unless profiles.length > 0
          }
                   .each { |profile|
              profile.devices = devices
              profile.update!
              UI.success "Applied #{devices.length} devices to #{profile.name}"
          }
        }
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Add devices to provisioning profiles'
      end

      def self.details
        'Add all iOS devices to any profiles associated with the provided bundle identifiers'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :app_identifier,
            description: 'List of App Identifiers that should contain the new device identifier',
            is_string: false,
            verify_block: proc do |value|
              UI.user_error!('You must provide an array of bundle identifiers in `app_identifier`') unless not value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :team_id,
            description: 'The team_id for the provisioning profiles',
            is_string: true,
            verify_block: proc do |value|
              UI.user_error!('You must provide a team ID in `team_id`') unless (value and not value.empty?)
            end
          ),
        ]
      end

      def self.output
        # This lane doesn't provide variables that other lanes can consume.
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['jkmassel']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
