module Fastlane
  module Actions
    class PrototypeBuildDetailsCommentAction < Action
      def self.run(params)
        appcenter_org_name = params[:appcenter_org_name]
        appcenter_app_name = params[:appcenter_app_name]
        appcenter_release_id = params[:appcenter_release_id]
        commit = params[:commit] || other_action.last_git_commit[:abbreviated_commit_hash]

        metadata = params[:metadata] # e.g. {'Build Config':… , 'Version': …, 'Short Version': …}

        install_url = "https://install.appcenter.ms/orgs/#{appcenter_org_name}/apps/#{appcenter_app_name}/releases/#{appcenter_release_id}"
        qr_code_url = "https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=#{CGI.escape(install_url)}&choe=UTF-8"

        metadata_rows = metadata.map do |key, value|
          "<tr><td><b>#{key}</b></td><td><tt>#{value}</tt></td></tr>"
        end.join("\n")

        <<~COMMENT_BODY
          <p>📲 You can test the changes from this Pull Request by scanning the QR code below with your phone to install the corresponding <strong>#{appcenter_app_name}</strong> build from App Center.</p>
          <table>
          <tr>
            <td rowspan='#{metadata.count + 3}'><img src='#{qr_code_url}' width='250' height='250' /></td>
            <td width='150px'><b>App</b></td><td><tt>#{appcenter_app_name}</tt></td>
          </tr>
          #{metadata_rows}
          <tr><td><b>App Center Build</b></td><td><a href='#{install_url}'>Build \##{appcenter_release_id}</a></td></tr>
          <tr><td><b>Commit</b></td><td><tt>#{commit}</tt></td></tr>
          </table>
          #{params[:footnote]}
        COMMENT_BODY
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates the nicely-formatted string providing all the details of a prototype build, ready to be used as a PR comment (e.g. via `comment_on_pr`).'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :appcenter_org_name,
            env_name: 'APPCENTER_OWNER_NAME', # Same as the one used by the `appcenter_upload` action
            description: 'The name of the organization in App Center',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :appcenter_app_name,
            env_name: 'APPCENTER_APP_NAME', # Same as the one used by the `appcenter_upload` action
            description: 'The name of the app in App Center',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :appcenter_release_id,
            env_name: 'FL_PROTOTYPE_BUILD_APPCENTER_RELEASE_ID',
            description: 'The release ID/Number in App Center',
            type: Integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :metadata,
            env_name: 'FL_PROTOTYPE_BUILD_DETAILS_COMMENT_METADATA',
            description: 'All additional metadata (as key/value pairs) you want to include in the HTML table of the comment',
            type: Hash,
            optional: true,
            default_value: {}
          ),
          FastlaneCore::ConfigItem.new(
            key: :footnote,
            env_name: 'FL_PROTOTYPE_BUILD_DETAILS_COMMENT_FOOTNOTE',
            description: 'Optional footnote to add below the HTML table of the comment',
            type: String,
            default_value: '<em>Automatticians: You can use our internal self-serve MC tool to give yourself access to App Center if needed.</em>'
          ),
          FastlaneCore::ConfigItem.new(
            key: :commit,
            env_name: 'BUILDKITE_COMMIT',
            description: 'The commit this prototype build was build from; usually not passed explicitly, but derived from the environment variable instead',
            type: String,
            optional: true
          ),
        ]
      end

      def self.return_type
        :string
      end

      def self.return_value
        'The HTML comment containing all the relevant info about a Prototype build published to App Center'
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
