module Fastlane
  module Actions
    class PrototypeBuildDetailsCommentAction < Action
      def self.run(params)
        app_display_name = params[:app_display_name]
        app_center_info = AppCenterInfo.from_params(params)
        metadata = consolidate_metadata(params, app_center_info)

        qr_code_url, extra_metadata = build_install_links(app_center_info, params[:download_url])
        metadata.merge!(extra_metadata)

        # Build the comment parts
        icon_img_tag = img_tag(params[:app_icon] || app_center_info.icon, alt: app_display_name)
        metadata_rows = metadata.compact.map { |key, value| "<tr><td><b>#{key}</b></td><td>#{value}</td></tr>" }
        intro = "#{icon_img_tag}📲 You can test the changes from this Pull Request in <b>#{app_display_name}</b> by scanning the QR code below to install the corresponding build."
        footnote = params[:footnote] || (app_center_info.org_name.nil? ? '' : DEFAULT_APP_CENTER_FOOTNOTE)
        body = <<~COMMENT_BODY
          <table>
          <tr>
            <td rowspan='#{metadata_rows.count + 1}' width='260px'><img src='#{qr_code_url}' width='250' height='250' /></td>
            <td><b>App Name</b></td><td>#{icon_img_tag} #{app_display_name}</td>
          </tr>
          #{metadata_rows.join("\n")}
          </table>
          #{footnote}
        COMMENT_BODY

        if params[:fold]
          "<details><summary>#{intro}</summary>\n#{body}</details>\n"
        else
          "<p>#{intro}</p>\n#{body}"
        end
      end

      #####################################################
      # @!group Helpers
      #####################################################

      NO_INSTALL_URL_ERROR_MESSAGE = <<~NO_URL_ERROR.freeze
        No URL provided to download or install the app.
         - Either use this action right after using `appcenter_upload` and provide an `app_center_org_name` (so that this action can use the link to the App Center build)
         - Or provide an explicit value for the `download_url` parameter
      NO_URL_ERROR

      DEFAULT_APP_CENTER_FOOTNOTE = '<em>Automatticians: You can use our internal self-serve MC tool to give yourself access to App Center if needed.</em>'.freeze

      # A small model struct to consolidate and pack all the values related to App Center
      #
      AppCenterInfo = Struct.new(:org_name, :app_name, :display_name, :release_id, :icon, :version, :short_version, :os, :bundle_id) do
        # A method to construct an AppCenterInfo instance from the action params, and infer the rest from the `lane_context` if available
        def self.from_params(params)
          org_name = params[:app_center_org_name]
          ctx = if org_name && defined?(SharedValues::APPCENTER_BUILD_INFORMATION)
                  Fastlane::Actions.lane_context[SharedValues::APPCENTER_BUILD_INFORMATION] || {}
                else
                  {}
                end
          app_name = params[:app_center_app_name] || ctx['app_name']
          new(
            org_name,
            app_name,
            ctx['app_display_name'] || app_name,
            params[:app_center_release_id] || ctx['id'],
            ctx['app_icon_url'],
            ctx['version'],
            ctx['short_version'],
            ctx['app_os'],
            ctx['bundle_identifier']
          )
        end
      end

      # Builds the installation link, QR code URL and extra metadata for download links from the available info
      #
      # @param [AppCenterInfo] app_center_info The struct containing all the values related to App Center info
      # @param [String] download_url The `download_url` parameter passed to the action, if one exists
      # @return [(String, Hash<String,String>)] A tuple containing:
      #   - The URL for the QR Code
      #   - A Hash of the extra metadata key/value pairs to add to the existing metadata, to enrich them with download/install links
      #
      def self.build_install_links(app_center_info, download_url)
        install_url = nil
        extra_metadata = {}
        if download_url
          install_url = download_url
          extra_metadata['Direct Download'] = "<a href='#{install_url}'><code>#{File.basename(install_url)}</code></a>"
        end
        if app_center_info.org_name && app_center_info.app_name
          install_url = "https://install.appcenter.ms/orgs/#{app_center_info.org_name}/apps/#{app_center_info.app_name}/releases/#{app_center_info.release_id}"
          extra_metadata['App Center Build'] = "<a href='#{install_url}'>#{app_center_info.display_name} ##{app_center_info.release_id}</a>"
        end
        UI.user_error!(NO_INSTALL_URL_ERROR_MESSAGE) if install_url.nil?
        qr_code_url = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&qzone=4&data=#{CGI.escape(install_url)}"
        [qr_code_url, extra_metadata]
      end

      # A method to build the Hash of metadata, based on the explicit ones passed by the user as parameter + the implicit ones from `AppCenterInfo`
      #
      # @param [Hash<Symbol, Any>] params The action's parameters, as received by `self.run`
      # @param [AppCenterInfo] app_center_info The model object containing all the values related to App Center information
      # @return [Hash<String, String>] A hash of all the metadata, gathered from both the explicit and the implicit ones
      #
      def self.consolidate_metadata(params, app_center_info)
        metadata = params[:metadata]&.transform_keys(&:to_s) || {}
        metadata['Build Number'] ||= app_center_info.version
        metadata['Version'] ||= app_center_info.short_version
        metadata[app_center_info.os == 'Android' ? 'Application ID' : 'Bundle ID'] ||= app_center_info.bundle_id
        # (Feel free to add more CI-specific env vars in the line below to support other CI providers if you need)
        metadata['Commit'] ||= ENV.fetch('BUILDKITE_COMMIT', nil) || other_action.last_git_commit[:abbreviated_commit_hash]
        metadata
      end

      # Creates an HTML `<img>` tag for an icon URL or the image URL to represent a given Buildkite emoji
      #
      # @param [String] url_or_emoji A `String` which can be:
      #  - Either a valid URI to an image
      #  - Or a string formatted like `:emojiname:`, using a valid Buildite emoji name as defined in https://github.com/buildkite/emojis
      # @param [String] alt The alt text to use for the `<img>` tag
      # @return [String] The `<img …>` tag with the proper image and alt tag
      #
      def self.img_tag(url_or_emoji, alt: '')
        return nil if url_or_emoji.nil?

        emoji = url_or_emoji.match(/:(.*):/)&.captures&.first
        app_icon_url = if emoji
                         "https://raw.githubusercontent.com/buildkite/emojis/main/img-buildkite-64/#{emoji}.png"
                       elsif URI(url_or_emoji)
                         url_or_emoji
                       end
        app_icon_url ? "<img alt='#{alt}' align='top' src='#{app_icon_url}' width='20px' />" : ''
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates a string providing all the details of a prototype build, nicely-formatted and ready to be used as a PR comment (e.g. via `comment_on_pr`).'
      end

      def self.details
        <<~DESC
          Generates a string providing all the details of a prototype build, nicely-formatted as HTML.
          The returned string will typically be subsequently used by the `comment_on_pr` action to post that HTML as comment on a PR.

          If you used the `appcenter_upload` lane (to upload the Prototype build to App Center) before calling this action, and pass
          a value to the `app_center_org_name` parameter, then many of the parameters and metadata will be automatically extracted
          from the `lane_context` provided by `appcenter_upload`, including:

           - The `app_center_app_name`, `app_center_release_id` and installation URL to use for the QR code to point to that release in App Center
           - The `app_icon`
           - The app's Build Number / versionCode
           - The app's Version / versionName
           - The app's Bundle ID / Application ID
           - A `footnote` mentioning the MC tool for Automatticians to add themselves to App Center

          This means that if you are using App Center to distribute your Prototype Build, the only parameters you *have* to provide
          to this action are `app_display_name` and `app_center_org_name`; plus, for `metadata` most of the interesting values will already be pre-filled.

          Any of those implicit default values/metadata can of course be overridden by passing an explicit value to the appropriate parameter(s).
        DESC
      end

      def self.available_options
        app_center_auto = '(will be automatically extracted from `lane_context if you used `appcenter_upload` to distribute your Prototype build)'
        [
          FastlaneCore::ConfigItem.new(
            key: :app_display_name,
            env_name: 'FL_PROTOTYPE_BUILD_DETAILS_COMMENT_APP_DISPLAY_NAME',
            description: 'The display name to use for the app in the comment message',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_center_org_name,
            env_name: 'APPCENTER_OWNER_NAME', # Intentionally the same as the one used by the `appcenter_upload` action
            description: 'The name of the organization in App Center (if you used `appcenter_upload` to distribute your Prototype build)',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_center_app_name,
            env_name: 'APPCENTER_APP_NAME', # Intentionally the same as the one used by the `appcenter_upload` action
            description: "The name of the app in App Center #{app_center_auto}",
            type: String,
            optional: true,
            default_value_dynamic: true # As it will be extracted from the `lane_context`` if you used `appcenter_upload``
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_center_release_id,
            env_name: 'APPCENTER_RELEASE_ID',
            description: "The release ID/Number in App Center #{app_center_auto}",
            type: String,
            optional: true,
            default_value_dynamic: true # As it will be extracted from the `lane_context`` if you used `appcenter_upload``
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_icon,
            env_name: 'FL_PROTOTYPE_BUILD_DETAILS_COMMENT_APP_ICON',
            description: "The name of an emoji from the https://github.com/buildkite/emojis list or the full image URL to use for the icon of the app in the message. #{app_center_auto}",
            type: String,
            optional: true,
            default_value_dynamic: true # As it will be extracted from the `lane_context`` if you used `appcenter_upload``
          ),
          FastlaneCore::ConfigItem.new(
            key: :download_url,
            env_name: 'FL_PROTOTYPE_BUILD_DETAILS_COMMENT_DOWNLOAD_URL',
            description: 'The URL to download the build as a direct download. ' \
             + 'If you uploaded the build to App Center, we recommend leaving this nil (the comment will use the URL to the App Center build for the QR code)',
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
            description: 'All additional metadata (as key/value pairs) you want to include in the HTML table of the comment. ' \
             + 'If you are running this action after `appcenter_upload`, some metadata will automatically be added to this list too',
            type: Hash,
            optional: true,
            default_value_dynamic: true # As some metadata will be auto-filled if you used `appcenter_upload`
          ),
          FastlaneCore::ConfigItem.new(
            key: :footnote,
            env_name: 'FL_PROTOTYPE_BUILD_DETAILS_COMMENT_FOOTNOTE',
            description: 'Optional footnote to add below the HTML table of the comment. ' \
             + 'If you are running this action after `appcenter_upload`, a default footnote for Automatticians will be used unless you provide an explicit value',
            type: String,
            optional: true,
            default_value_dynamic: true # We have a default footnote for the case when you used App Center
          ),
        ]
      end

      def self.return_type
        :string
      end

      def self.return_value
        'The HTML comment containing all the relevant info about a Prototype build and links to install it'
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
