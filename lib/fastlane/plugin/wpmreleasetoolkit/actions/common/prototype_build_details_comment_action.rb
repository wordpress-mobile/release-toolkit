# frozen_string_literal: true

require 'cgi'
require 'uri'

module Fastlane
  module Actions
    class PrototypeBuildDetailsCommentAction < Action
      def self.run(params)
        app_display_name = params[:app_display_name]
        download_url = params[:download_url]
        release_info = FirebaseReleaseInfo.from_lane_context

        # Merge explicit extra metadata passed from params with ones derived from FirebaseReleaseInfo
        metadata = generate_metadata_hash(params: params, release_info: release_info)
        # Build the installation link, QR code URL and extra metadata for download links from the available info
        qr_code_url, extra_metadata = install_links(release_info: release_info, download_url: download_url)
        metadata.merge!(extra_metadata)

        # Build the comment parts and body
        app_icon = params[:app_icon]
        app_icon ||= ':firebase:' if !release_info.nil? || (download_url && is_firebase_url?(download_url))
        intro = "#{img_tag(app_icon)}📲 You can test the changes from this Pull Request in <b>#{CGI.escape_html(app_display_name)}</b> by scanning the QR code below to install the corresponding build."
        metadata_rows = metadata.compact.map { |key, value| "<tr><td><b>#{key}</b></td><td>#{value}</td></tr>" }
        footnote = params[:footnote]
        footnote ||= DEFAULT_FOOTNOTE if !release_info.nil? || (download_url && is_firebase_url?(download_url))

        body = <<~COMMENT_BODY.chomp('')
          <table>
          <tr>
            <td rowspan='#{metadata_rows.count + 1}' width='260px'><img src='#{qr_code_url}' width='250' height='250' /></td>
            <td><b>App Name</b></td><td>#{CGI.escape_html(app_display_name)}</td>
          </tr>
          #{metadata_rows.join("\n")}
          </table>
          #{footnote}
        COMMENT_BODY

        if params[:fold]
          "<details><summary>#{intro}</summary>\n#{body}\n</details>\n"
        else
          "<p>#{intro}</p>\n#{body}\n"
        end
      end

      #####################################################
      # @!group Helpers
      #####################################################

      NO_INSTALL_URL_ERROR_MESSAGE = <<~NO_URL_ERROR
        No URL provided to download or install the app.
         - Either use this action right after using `firebase_app_distribution` so this action can extract the download URL from the `lane_context`
         - Or provide an explicit value for the `download_url` parameter
      NO_URL_ERROR

      DEFAULT_FOOTNOTE = '<em>Automatticians: You can use our internal self-serve MC tool to give yourself access to those builds if needed.</em>'

      # Parse and validate a URL string
      #
      # @param [String] url The URL string to parse and validate
      # @return [URI] The parsed URI object
      # @raise [FastlaneCore::Interface::FastlaneError] if the URL is invalid
      #
      def self.parse_url!(url)
        URI.parse(url).tap do |uri|
          raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        end
      rescue URI::InvalidURIError
        UI.user_error!("Invalid URL: #{url}")
      end

      # A small model/struct representing values exposed by Firebase App Distribution for a given release
      #
      FirebaseReleaseInfo = Struct.new(:display_version, :build_version, :testing_url, :os, :bundle_id, :release_id) do
        def self.from_lane_context
          return nil unless defined?(SharedValues::FIREBASE_APP_DISTRO_RELEASE)

          ctx = Fastlane::Actions.lane_context[SharedValues::FIREBASE_APP_DISTRO_RELEASE]
          return nil if ctx.nil?

          # Extract platform info from Firebase Console URI
          if ctx[:firebaseConsoleUri]
            uri = URI(ctx[:firebaseConsoleUri])
            os, bundle_id, release_id = uri.path.match(%r{project/.*/appdistribution/app/([^:]*):([^/]*)/releases/(.*)})&.captures
          end

          new(
            display_version: ctx[:displayVersion],
            build_version: ctx[:buildVersion],
            testing_url: ctx[:testingUri],
            os: os,
            bundle_id: bundle_id,
            release_id: release_id
          )
        end
      end

      # Constructs the Hash of metadata, based on the explicit ones passed by the user as parameter + the implicit ones from `FirebaseReleaseInfo`
      #
      # @param [Hash<Symbol, Any>] params The action's parameters, as received by `self.run`
      # @param [FirebaseReleaseInfo?] release_info The information about the Firebase Release extracted from the `lane_context`
      # @return [Hash<String, String>] A hash of all the metadata, consolidated from both the explicit and the implicit ones
      #
      def self.generate_metadata_hash(params:, release_info:)
        # Add explicit metadata provided by the caller
        metadata = params[:metadata]&.transform_keys(&:to_s) || {}

        # Add Firebase-specific metadata if available
        unless release_info.nil?
          metadata['Build Number'] ||= "<code>#{release_info.build_version}</code>"
          metadata['Version'] ||= "<code>#{release_info.display_version}</code>"
          metadata[release_info.os == 'ios' ? 'Bundle ID' : 'Application ID'] ||= "<code>#{release_info.bundle_id}</code>"
        end

        # Add git metadata
        metadata['Commit'] ||= ENV.fetch('BUILDKITE_COMMIT', nil) || other_action.last_git_commit[:abbreviated_commit_hash]
        metadata
      end

      # Constructs the installation link, QR code URL and extra metadata for download links from the available info
      #
      # @param [FirebaseReleaseInfo?] release_info The information about the Firebase Release extracted from the `lane_context`
      # @param [String] download_url The `download_url` parameter passed to the action, if one was provided
      # @return [(String, Hash<String,String>)] A tuple containing:
      #   - The URL for the QR Code
      #   - A Hash of the extra metadata key/value pairs to add to the existing metadata, to enrich them with download/install links
      # @raise [FastlaneCore::Interface::FastlaneError] if no valid installation URL could be determined
      #
      def self.install_links(release_info:, download_url:)
        install_url = nil
        extra_metadata = {}
        firebase_release_id = nil

        # Validate and process direct download URL if provided
        if download_url
          uri = parse_url!(download_url)
          install_url = download_url

          if is_firebase_url?(uri)
            firebase_release_id = File.basename(uri.path)
          else
            filename = File.basename(uri.path)
            extra_metadata['Direct Download'] = "<a href='#{CGI.escape_html(install_url)}'><code>#{CGI.escape_html(filename)}</code></a>"
          end
        end

        # Process Firebase testing URL if available from release_info
        if release_info&.testing_url
          install_url = release_info.testing_url
          firebase_release_id = release_info.release_id
        end

        UI.user_error!(NO_INSTALL_URL_ERROR_MESSAGE) if install_url.nil?

        # Add Installation URL metadata if we have a release_id
        extra_metadata['Installation URL'] = "<a href='#{CGI.escape_html(install_url)}'>#{CGI.escape_html(firebase_release_id)}</a>" if firebase_release_id

        # Generate QR code URL with proper escaping
        qr_code_url = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&qzone=4&data=#{CGI.escape(install_url)}"
        [qr_code_url, extra_metadata]
      end

      # Determines if a given URI is a Firebase App Distribution URL
      #
      # @param [String, URI] url The URL to check, either as a String or an already-parsed URI
      # @return [Boolean] true if the URL is a Firebase App Distribution URL
      # @raise [FastlaneCore::Interface::FastlaneError] if the URL is invalid
      #
      def self.is_firebase_url?(url)
        uri = url.is_a?(URI) ? url : parse_url!(url)
        uri.host == 'appdistribution.firebase.google.com' && uri.path.start_with?('/testerapps/')
      end

      # Creates an HTML `<img>` tag for an icon URL or the image URL to represent a given Buildkite emoji
      #
      # @param [String] url_or_emoji A `String` which can be:
      #  - Either a valid URI to an image
      #  - Or a string formatted like `:emojiname:`, using a valid Buildite emoji name as defined in https://github.com/buildkite/emojis
      # @return [String] The `<img …>` tag with the proper image and alt tag
      # @raise [FastlaneCore::Interface::FastlaneError] if the URL is invalid
      #
      def self.img_tag(url_or_emoji)
        return nil if url_or_emoji.nil?

        emoji = url_or_emoji.match(/:(.*):/)&.captures&.first
        app_icon_url = if emoji
                         "https://raw.githubusercontent.com/buildkite/emojis/main/img-buildkite-64/#{emoji}.png"
                       else
                         url_or_emoji.tap { parse_url!(url_or_emoji) }
                       end
        app_icon_url ? "<img align='top' src='#{app_icon_url}' width='20px' alt='App Icon' />" : ''
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

          If you used the `firebase_app_distribution` action (to upload the Prototype build to Firebase App Distribution) before calling this action,
          then many of the metadata will be automatically extracted from the `lane_context` it exposed:

          - "Version" (from `:displayVersion`) and "Build Number" (from `:buildVersion`)
          - "Bundle ID" (extracted from `:firebaseConsoleUri`)
          - "Commit" (from `BUILDKITE_COMMIT` environment variable or last git commit)
          - "Installation URL" (from `:testingUri`)

          You can also pass additional metadata to this action via the `metadata` parameter, and they will also be included in the HTML table of the comment.

          This means that if you are using Firebase App Distribution to distribute your Prototype Build, the can just provide
          `app_display_name` and optionally `app_icon`, and the rest will be automatically inferred from the `lane_context`.

          If you are not using Firebase App Distribution, you can pass an explicit value for the `download_url` parameter,
          and the action will use it to generate the installation link and QR code.
        DESC
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :app_display_name,
            description: 'The display name to use for the app in the comment message',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_icon,
            description: 'The name of an emoji from the https://github.com/buildkite/emojis list or the full image URL to use for the icon of the app in the message',
            type: String,
            optional: true,
            default_value_dynamic: true # Defaults to `:firebase:` only if `firebase_app_distribution` was used
          ),
          FastlaneCore::ConfigItem.new(
            key: :download_url,
            description: <<~DESC,
              The URL to use to download/install the build.
              - If you used `firebase_app_distribution` to upload the build during the same `fastlane` run, you should leave this nil
              - If you used `firebase_app_distribution` during a separate CI job, you can store the `:testingUri` of that call's returned hash (in e.g. Buildkite metadata), then pass that URI to this parameter
              - Otherwise, you can provide a direct download URL for the build (e.g. link to Cloudfront or AppsCDN URL)
            DESC
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :fold,
            description: 'If true, will wrap the HTML table inside a <details> block (hidden by default)',
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :metadata,
            description: 'All additional metadata (as key/value pairs) you want to include in the HTML table of the comment. ' \
             + 'If you are running this action after `firebase_app_distribution`, some metadata will automatically be added and merged with this list',
            type: Hash,
            optional: true,
            default_value_dynamic: true # As some metadata will be auto-filled if you used `firebase_app_distribution`
          ),
          FastlaneCore::ConfigItem.new(
            key: :footnote,
            description: 'Optional footnote to add below the HTML table of the comment. ' \
             + 'If you are running this action after `firebase_app_distribution`, a default footnote for Automatticians will be used unless you provide an explicit value',
            type: String,
            optional: true,
            default_value_dynamic: true # We have a default footnote for the case when you used Firebase App Distribution
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
