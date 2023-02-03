module Fastlane
  module Actions
    class PrototypeBuildDetailsCommentAction < Action
      def self.run(params)
        # Get Input Parameters
        appcenter_org_name = params[:appcenter_org_name]
        appcenter_app_name = params[:appcenter_app_name]
        appcenter_release_id = params[:appcenter_release_id]
        commit = params[:commit] || other_action.last_git_commit[:abbreviated_commit_hash]

        metadata = params[:metadata] # e.g. {'Build Config':… , 'Version': …, 'Short Version': …}
        direct_link = params[:download_url]
        unless direct_link.nil?
          metadata['Direct Link'] = "<a href='#{direct_link}'><tt>#{File.basename(direct_link)}</tt></a>"
        end

        # Build the comment parts
        install_url = "https://install.appcenter.ms/orgs/#{appcenter_org_name}/apps/#{appcenter_app_name}/releases/#{appcenter_release_id}"
        qr_code_url = "https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=#{CGI.escape(install_url)}&choe=UTF-8"
        metadata_rows = metadata.compact.map do |key, value|
          "<tr><td><b>#{key}</b></td><td>#{value}</td></tr>"
        end

        intro = "📲 You can test the changes from this Pull Request in <strong>#{appcenter_app_name}</strong> by scanning the QR code below to install the corresponding build via App Center."
        body = <<~COMMENT_BODY
          <table>
          <tr>
            <td rowspan='#{metadata.count + 3}'><img src='#{qr_code_url}' width='250' height='250' /></td>
            <td width='150px'><b>App Name</b></td><td><tt>#{appcenter_app_name}</tt></td>
          </tr>
          #{metadata_rows.join("\n")}
          <tr><td><b>App Center Build</b></td><td><a href='#{install_url}'>Build \##{appcenter_release_id}</a></td></tr>
          <tr><td><b>Commit</b></td><td><tt>#{commit}</tt></td></tr>
          </table>
          #{params[:footnote]}
        COMMENT_BODY

        if params[:fold]
          "<details><summary>#{intro}</summary>\n#{body}</details>\n"
        else
          "<p>#{intro}</p>\n#{body}"
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates a string providing all the details of a prototype build, nicely-formatted and ready to be used as a PR comment (e.g. via `comment_on_pr`).'
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
            description: "The release ID/Number in App Center; can be obtained using `lane_context[SharedValues::APPCENTER_BUILD_INFORMATION]['id']`",
            type: Integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :download_url,
            env_name: 'FL_PROTOTYPE_BUILD_DOWNLOAD_URL',
            description: 'The URL to download the build directly; e.g. a public link to the `.apk` file; you might use `lane_context[SharedValues::APPCENTER_DOWNLOAD_LINK]` for this for example',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :fold,
            env_name: 'FL_PROTOTYPE_BUILD_DETAILS_COMMENT_FOLD',
            description: 'If true, will wrap the HTML table inside a <details> block (hidden by default)',
            type: Boolean,
            default_value: false
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
