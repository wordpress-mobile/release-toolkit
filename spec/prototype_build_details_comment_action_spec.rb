require_relative './spec_helper'

describe Fastlane::Actions::PrototypeBuildDetailsCommentAction do
  before do
    ENV['BUILDKITE_COMMIT'] = 'a1b2c3f'
  end

  describe 'cases common to all operating modes' do
    it 'includes the app display name as part of the intro text' do
      comment = run_described_fastlane_action(
        app_display_name: 'My Cool App',
        download_url: 'https://localhost/foo.apk'
      )
      expect(comment).to include 'You can test the changes from this Pull Request in <b>My Cool App</b>'
    end

    it 'includes the commit as part of the default rows' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        download_url: 'https://localhost/foo.apk'
      )
      expect(comment).to include '<td><b>Commit</b></td><td>a1b2c3f</td>'
    end

    it 'includes the provided footnote if one was provided explicitly' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        download_url: 'https://localhost/foo.apk',
        footnote: '<em>Note that Google Sign-In in not available in those builds</em>'
      )
      expect(comment).to include '<em>Note that Google Sign-In in not available in those builds</em>'
    end
  end

  context 'when using App Center with explicit parameters' do
    it 'raises an error if neither `app_center_app_name` nor `download_url` is provided' do
      expected_message = <<~ERROR
        No URL provided to download or install the app.
         - Either use this action right after using `appcenter_upload` and provide an `app_center_org_name` (so that this action can use the link to the App Center build)
         - Or provide an explicit value for the `download_url` parameter
      ERROR

      expect do
        run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'BestOrg'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, expected_message)
    end

    describe 'checking specific content is present' do
      it 'generates the proper App Center link and QR code given an org, app name and release ID' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'My-Org',
          app_center_app_name: 'My-App',
          app_center_release_id: '1337'
        )
        expect(comment).to include "<a href='https://install.appcenter.ms/orgs/My-Org/apps/My-App/releases/1337'>My-App #1337</a>"
        expect(comment).to include 'https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FMy-Org%2Fapps%2FMy-App%2Freleases%2F1337&choe=UTF-8'
      end

      it 'includes both explicit and implicit metadata when some are provided by the user' do
        metadata = {
          'Version:Short': '28.1',
          'Version:Long': '281003',
          'Build Config': 'Prototype'
        }
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'My-Org',
          app_center_app_name: 'My-App',
          app_center_release_id: '1337',
          metadata: metadata
        )
        expect(comment).to include '<td><b>App Name</b></td><td> My App</td>'
        expect(comment).to include '<td><b>Version:Short</b></td><td>28.1</td>'
        expect(comment).to include '<td><b>Version:Long</b></td><td>281003</td>'
        expect(comment).to include '<td><b>Build Config</b></td><td>Prototype</td>'
        expect(comment).to include '<td><b>Commit</b></td><td>a1b2c3f</td>'
        expect(comment).to include "<tr><td><b>App Center Build</b></td><td><a href='https://install.appcenter.ms/orgs/My-Org/apps/My-App/releases/1337'>My-App \#1337</a></td></tr>"
        # Additional inferred metadata rows: App Name, Commit, App Center Build
        expect(comment).to include "<td rowspan='6'"
      end

      it 'includes use the App Center link for the QR code even if a download_url is provided' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'My-Org',
          app_center_app_name: 'My-App',
          app_center_release_id: '1337',
          download_url: 'https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'
        )
        expect(comment).to include "<td><b>Direct Download</b></td><td><a href='https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'><code>myapp-prototype-build-pr1337-a1b2c3f.apk</code></a></td>"
        expect(comment).to include 'https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FMy-Org%2Fapps%2FMy-App%2Freleases%2F1337&choe=UTF-8'
        # Inferred metadata rows: App Name, Commit, Direct Download, App Center Build
        expect(comment).to include "<td rowspan='4'"
      end

      it 'includes the default footnote about App Center if not overridden' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'BestOrg',
          app_center_app_name: 'MyApp',
          app_center_release_id: '1337'
        )
        expect(comment).to include '<em>Automatticians: You can use our internal self-serve MC tool to give yourself access to App Center if needed.</em>'
      end
    end

    describe 'validating full comment' do
      it 'generates a standard HTML table comment by default, with all the information provided' do
        metadata = {
          'Version:Short': '28.2',
          'Version:Long': '28.2.0.108',
          Flavor: 'Celray'
        }

        comment = run_described_fastlane_action(
          app_display_name: 'The Best App',
          app_center_org_name: 'BestOrg',
          app_center_app_name: 'BestApp',
          app_center_release_id: '8888',
          metadata: metadata,
          footnote: '<em>Note: Google Sign-In in not available in those builds</em>'
        )

        expect(comment).to eq <<~EXPECTED_COMMENT
          <p>📲 You can test the changes from this Pull Request in <b>The Best App</b> by scanning the QR code below to install the corresponding build.</p>
          <table>
          <tr>
            <td rowspan='6' width='260px'><img src='https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FBestOrg%2Fapps%2FBestApp%2Freleases%2F8888&choe=UTF-8' width='250' height='250' /></td>
            <td><b>App Name</b></td><td> The Best App</td>
          </tr>
          <tr><td><b>Version:Short</b></td><td>28.2</td></tr>
          <tr><td><b>Version:Long</b></td><td>28.2.0.108</td></tr>
          <tr><td><b>Flavor</b></td><td>Celray</td></tr>
          <tr><td><b>Commit</b></td><td>a1b2c3f</td></tr>
          <tr><td><b>App Center Build</b></td><td><a href='https://install.appcenter.ms/orgs/BestOrg/apps/BestApp/releases/8888'>BestApp \#8888</a></td></tr>
          </table>
          <em>Note: Google Sign-In in not available in those builds</em>
        EXPECTED_COMMENT
      end

      it 'generates a HTML table comment including the direct link if provided' do
        metadata = {
          'Version:Short': '28.2',
          'Version:Long': '28.2.0.108'
        }

        comment = run_described_fastlane_action(
          app_display_name: 'The Best App',
          app_center_org_name: 'BestOrg',
          app_center_app_name: 'BestApp',
          app_center_release_id: '8888',
          download_url: 'https://bestfront.cloudfront.net/feed42/bestapp-pr1357-a1b2c3f.apk',
          metadata: metadata
        )

        expect(comment).to eq <<~EXPECTED_COMMENT
          <p>📲 You can test the changes from this Pull Request in <b>The Best App</b> by scanning the QR code below to install the corresponding build.</p>
          <table>
          <tr>
            <td rowspan='6' width='260px'><img src='https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FBestOrg%2Fapps%2FBestApp%2Freleases%2F8888&choe=UTF-8' width='250' height='250' /></td>
            <td><b>App Name</b></td><td> The Best App</td>
          </tr>
          <tr><td><b>Version:Short</b></td><td>28.2</td></tr>
          <tr><td><b>Version:Long</b></td><td>28.2.0.108</td></tr>
          <tr><td><b>Commit</b></td><td>a1b2c3f</td></tr>
          <tr><td><b>Direct Download</b></td><td><a href='https://bestfront.cloudfront.net/feed42/bestapp-pr1357-a1b2c3f.apk'><code>bestapp-pr1357-a1b2c3f.apk</code></a></td></tr>
          <tr><td><b>App Center Build</b></td><td><a href='https://install.appcenter.ms/orgs/BestOrg/apps/BestApp/releases/8888'>BestApp \#8888</a></td></tr>
          </table>
          <em>Automatticians: You can use our internal self-serve MC tool to give yourself access to App Center if needed.</em>
        EXPECTED_COMMENT
      end

      it 'generates a HTML table in a spoiler block if fold is true' do
        metadata = {
          'Version:Short': '28.2',
          'Version:Long': '28.2.0.108',
          Flavor: 'Celray',
          Configuration: 'Debug'
        }

        comment = run_described_fastlane_action(
          app_display_name: 'The Best App',
          app_center_org_name: 'BestOrg',
          app_center_app_name: 'BestApp',
          app_center_release_id: '1234',
          fold: true,
          metadata: metadata,
          footnote: '<em>Note: Google Sign-In in not available in those builds</em>'
        )

        expect(comment).to eq <<~EXPECTED_COMMENT
          <details><summary>📲 You can test the changes from this Pull Request in <b>The Best App</b> by scanning the QR code below to install the corresponding build.</summary>
          <table>
          <tr>
            <td rowspan='7' width='260px'><img src='https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FBestOrg%2Fapps%2FBestApp%2Freleases%2F1234&choe=UTF-8' width='250' height='250' /></td>
            <td><b>App Name</b></td><td> The Best App</td>
          </tr>
          <tr><td><b>Version:Short</b></td><td>28.2</td></tr>
          <tr><td><b>Version:Long</b></td><td>28.2.0.108</td></tr>
          <tr><td><b>Flavor</b></td><td>Celray</td></tr>
          <tr><td><b>Configuration</b></td><td>Debug</td></tr>
          <tr><td><b>Commit</b></td><td>a1b2c3f</td></tr>
          <tr><td><b>App Center Build</b></td><td><a href='https://install.appcenter.ms/orgs/BestOrg/apps/BestApp/releases/1234'>BestApp \#1234</a></td></tr>
          </table>
          <em>Note: Google Sign-In in not available in those builds</em>
          </details>
        EXPECTED_COMMENT
      end
    end
  end

  context 'when using App Center and relying on implicit info from `lane_context`' do
    before do
      stub_const('Fastlane::Actions::SharedValues::APPCENTER_BUILD_INFORMATION', :fake_app_center_build_info)

      lane_ctx = {
        app_name: 'My-App-Alpha',
        app_display_name: 'My App (Alpha)',
        id: '1337',
        version: '1287003',
        short_version: '28.7',
        app_os: 'Android',
        bundle_identifier: 'com.stubfactory.myapp',
        app_icon_url: 'https://assets.appcenter.ms/My-App-Alpha/1337/icon.png'
      }.transform_keys(&:to_s)

      allow(described_class).to receive(:lane_context).and_return({ fake_app_center_build_info: lane_ctx })
    end

    describe 'checking specific content is present' do
      it 'generates the proper App Center link and QR code given just an org' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'My-Org'
        )
        expect(comment).to include "<a href='https://install.appcenter.ms/orgs/My-Org/apps/My-App-Alpha/releases/1337'>My App (Alpha) #1337</a>"
        expect(comment).to include 'https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FMy-Org%2Fapps%2FMy-App-Alpha%2Freleases%2F1337&choe=UTF-8'
      end

      it 'includes and prioritize user-provided metadata over implicit ones' do
        metadata = {
          'Version': '42.3',
          'Build Number': '4203008',
          'Build Config': 'Prototype'
        }
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'My-Org',
          metadata: metadata
        )
        expect(comment).to include '<td><b>Version</b></td><td>42.3</td>' # explicitly provided, overriding the implicit value
        expect(comment).not_to include '<td><b>Version</b></td><td>28.7</td>' # otherwise implicitly added if it were not overridden
        expect(comment).to include '<td><b>Build Number</b></td><td>4203008</td>' # explicitly provided, overriding the implicit value
        expect(comment).not_to include '<td><b>Build Number</b></td><td>1287003</td>' # otherwise implicitly added if it were not overridden
        expect(comment).to include '<td><b>Build Config</b></td><td>Prototype</td>' # an explicit metadata not overriding any implicit one
        # Additional inferred metadata rows: App Name, Application ID, Commit, App Center Build
        expect(comment).to include "<td rowspan='7'"
      end

      it 'includes the direct link if one is provided' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'My-Org',
          download_url: 'https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'
        )
        expect(comment).to include "<td><b>Direct Download</b></td><td><a href='https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'><code>myapp-prototype-build-pr1337-a1b2c3f.apk</code></a></td>"
        # Inferred metadata rows: App Name, Build Number, Version, Application ID, Commit, Direct Download, App Center Build
        expect(comment).to include "<td rowspan='7'"
      end

      it 'includes the App Center default footnote if no explicit footnote is provided' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'BestOrg'
        )
        expect(comment).to include '<em>Automatticians: You can use our internal self-serve MC tool to give yourself access to App Center if needed.</em>'
      end

      it 'includes the provided footnote if one was provided explicitly' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          app_center_org_name: 'My-Org',
          footnote: '<em>Note that Google Sign-In in not available in those builds</em>'
        )
        expect(comment).to include '<em>Note that Google Sign-In in not available in those builds</em>'
      end
    end

    describe 'validating full comment' # TODO
  end

  context 'when not using App Center' do
    it 'raises an error if no `download_url` is provided' do
      expected_message = <<~ERROR
        No URL provided to download or install the app.
         - Either use this action right after using `appcenter_upload` and provide an `app_center_org_name` (so that this action can use the link to the App Center build)
         - Or provide an explicit value for the `download_url` parameter
      ERROR

      expect do
        run_described_fastlane_action(
          app_display_name: 'My App'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, expected_message)
    end

    describe 'checking specific content is present' do
      it 'generates the proper QR code from the download url' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          download_url: 'https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'
        )
        expect(comment).to include 'https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Ffoo.cloudfront.net%2Fsomeuuid%2Fmyapp-prototype-build-pr1337-a1b2c3f.apk&choe=UTF-8'
      end

      it 'includes the direct link as metadata' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          download_url: 'https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'
        )
        expect(comment).to include "<td><b>Direct Download</b></td><td><a href='https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'><code>myapp-prototype-build-pr1337-a1b2c3f.apk</code></a></td>"
      end

      it 'does not include the App Center default footnote if no explicit footnote is provided' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          download_url: 'https://localhost/foo.apk'
        )
        expect(comment).not_to include '<em>Automatticians: You can use our internal self-serve MC tool to give yourself access to App Center if needed.</em>'
      end

      it 'includes the provided footnote if one was provided explicitly' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          download_url: 'https://localhost/foo.apk',
          footnote: 'The link to this APK might stop working after a retention delay of 30 days.'
        )
        expect(comment).to include 'The link to this APK might stop working after a retention delay of 30 days.'
      end
    end

    describe 'validating full comment' # TODO
  end
end
