require 'securerandom'

module Fastlane
  module Actions
    class FirebaseLoginAction < Action
      def self.run(params)
        Fastlane::FirebaseAccount.activate_service_account_with_key_file(params[:key_file])
      end

      #####################################################
      # @!group Documentation
      #####################################################
      def self.description
        'Logs the local machine into Google Cloud using the provided key file'
      end

      def self.details
        description
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :key_file,
            description: 'The key file used to authorize with Google Cloud',
            type: String,
            verify_block: proc do |value|
              UI.user_error!('The `:key_file` parameter is required') if value.empty?
              UI.user_error!("No Google Cloud Key file found at: #{value}") unless File.exist?(value)
            end
          ),
        ]
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
