module Fastlane
  module Actions
    class AddDevelopmentCertificatesToProvisioningProfilesAction < Action
      def self.run(params)
        require 'spaceship'

        Spaceship.login
        Spaceship.select_team(team_id: params[:team_id])

        all_certificates = Spaceship.certificate.all(mac: false).select do |certificate|
          certificate.owner_type == 'teamMember'
        end

        params[:app_identifier].each do |identifier|
          Spaceship.provisioning_profile.find_by_bundle_id(bundle_id: identifier)
                   .select do |profile|
            profile.is_a? Spaceship::Portal::ProvisioningProfile::Development
          end
                   .tap do |profiles|
            UI.important "Warning: Unable to find any profiles associated with #{identifier}" unless profiles.length > 0
          end
                   .each do |profile|
            profile.certificates = all_certificates
            profile.update!
            UI.success "Applied #{all_certificates.length} certificates to #{profile.name}"
          end
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Add dev certificates to provisioning profiles'
      end

      def self.details
        "Add all team member's development certificates to profiles associated with the provided bundle identifiers"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       description: 'List of App Identifiers that should contain the new device identifier',
                                       type: Array,
                                       verify_block: proc do |value|
                                                       UI.user_error!('You must provide an array of bundle identifiers in `app_identifier`') if value.empty?
                                                     end),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       description: 'The team_id for the provisioning profiles',
                                       type: String,
                                       verify_block: proc do |value|
                                                       UI.user_error!('You must provide a team ID in `team_id`') unless value && (!value.empty?)
                                                     end),
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
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
