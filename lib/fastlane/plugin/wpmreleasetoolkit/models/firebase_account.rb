module Fastlane
  class FirebaseAccount
    def self.activate_service_account_with_key_file(key_file_path)
      Fastlane::Actions.sh('gcloud', 'auth', 'activate-service-account', '--key-file', key_file_path)
    end

    def self.authenticated?
      auth_status = JSON.parse(auth_status_data)
      auth_status.any? do |account|
        account['status'] == 'ACTIVE'
      end
    end

    # Lookup the current account authentication status
    def self.auth_status_data
      Fastlane::Actions.sh('gcloud', 'auth', 'list', '--format', 'json', log: false)
    end
  end
end
