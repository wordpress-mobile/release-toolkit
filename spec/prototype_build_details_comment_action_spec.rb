# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Actions::PrototypeBuildDetailsCommentAction do
  before do
    ENV['BUILDKITE_COMMIT'] = 'a1b2c3f'
  end

  let(:custom_footnote) { '<em>Note: Google Sign-In is not available in those builds</em>' }
  let(:valid_download_url) { 'https://example.com/myapp.apk' }
  let(:valid_app_icon_url) { 'https://localhost/foo.png' }
  let(:base_params) do
    {
      app_display_name: 'My App',
      download_url: valid_download_url
    }
  end

  describe 'error handling' do
    it 'raises an error if neither Firebase info nor download_url is provided' do
      allow(Fastlane::Actions).to receive(:lane_context).and_return({})
      expect do
        run_described_fastlane_action(app_display_name: 'My App')
      end.to raise_error(FastlaneCore::Interface::FastlaneError, described_class::NO_INSTALL_URL_ERROR_MESSAGE)
    end

    describe 'URL validation' do
      it 'raises an error for invalid download URLs' do
        expect do
          run_described_fastlane_action(base_params.merge(download_url: 'not-a-url'))
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /Invalid URL/)
      end

      it 'raises an error for invalid app icon URLs' do
        expect do
          run_described_fastlane_action(base_params.merge(app_icon: 'not-a-url'))
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /Invalid URL/)
      end

      it 'accepts valid URLs with special characters' do
        url_with_special_chars = 'https://example.com/path%20with%20spaces.apk'
        expect do
          run_described_fastlane_action(base_params.merge(download_url: url_with_special_chars))
        end.not_to raise_error
      end
    end
  end

  describe 'HTML escaping' do
    let(:app_name_with_html) { 'My <em>Cool</em> App' }
    let(:metadata_with_html) do
      {
        'HTML Key': '<b>bold</b>',
        Link: '<a href="https://example.com">example.com</a>',
        'Mixed &amp; Content': 'Version &amp; Build <strong>1.0</strong>'
      }
    end

    it 'properly escapes HTML in app display name' do
      comment = run_described_fastlane_action(base_params.merge(app_display_name: app_name_with_html))
      expect(comment).to include '&lt;em&gt;Cool&lt;/em&gt;'
      expect(comment).not_to include '<em>'
    end

    it 'does not escape HTML in metadata' do
      comment = run_described_fastlane_action(base_params.merge(metadata: metadata_with_html))
      # HTML in metadata should be preserved as-is, so we can e.g. use links or <code> tags
      expect(comment).to include '<tr><td><b>HTML Key</b></td><td><b>bold</b></td>'
      expect(comment).to include '<tr><td><b>Link</b></td><td><a href="https://example.com">example.com</a></td>'
      expect(comment).to include '<tr><td><b>Mixed &amp; Content</b></td><td>Version &amp; Build <strong>1.0</strong></td>'
    end
  end

  describe 'metadata handling' do
    it 'handles empty metadata gracefully' do
      comment = run_described_fastlane_action(base_params.merge(metadata: {}))
      # Should still include default metadata
      expect(comment).to include '<td><b>App Name</b></td>'
      expect(comment).to include '<td><b>Commit</b></td>'
    end

    it 'handles nil metadata values' do
      comment = run_described_fastlane_action(base_params.merge(metadata: { 'Nil Value': nil }))
      expect(comment).not_to include '<td><b>Nil Value</b></td>'
    end

    it 'handles very long metadata values' do
      long_value = 'a' * 1000
      comment = run_described_fastlane_action(base_params.merge(metadata: { 'Long Value': long_value }))
      expect(comment).to include long_value
    end
  end

  describe 'cases common to all operating modes' do
    describe 'app_display_name' do
      it 'includes the app display name as part of the intro text' do
        comment = run_described_fastlane_action(
          app_display_name: 'My Cool App & Co.',
          download_url: 'https://localhost/foo.apk'
        )
        expect(comment).to include '📲 You can test the changes from this Pull Request in <b>My Cool App &amp; Co.</b>'
      end

      it 'includes the app display name as part of implicit metadata' do
        comment = run_described_fastlane_action(
          app_display_name: 'My Cool App & Co.',
          download_url: 'https://localhost/foo.apk'
        )
        expect(comment).to include '<td><b>App Name</b></td><td>My Cool App &amp; Co.</td>'
      end
    end

    describe 'app_icon' do
      context 'when providing an URL' do
        it 'includes the icon in the intro text' do
          comment = run_described_fastlane_action(
            app_display_name: 'My Cool App',
            app_icon: 'https://localhost/foo.png',
            download_url: 'https://localhost/foo.apk'
          )
          expect(comment).to include "<img align='top' src='https://localhost/foo.png' width='20px' alt='App Icon' />📲 "
        end
      end

      context 'when providing an emoji code' do
        it 'includes the icon in the intro text' do
          comment = run_described_fastlane_action(
            app_display_name: 'My Cool App',
            app_icon: ':jetpack:',
            download_url: 'https://localhost/foo.apk'
          )
          expect(comment).to include "<img align='top' src='https://raw.githubusercontent.com/buildkite/emojis/main/img-buildkite-64/jetpack.png' width='20px' alt='App Icon' />📲 "
        end
      end
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
        footnote: custom_footnote
      )
      expect(comment).to include custom_footnote
    end
  end

  context 'when using Firebase App Distribution' do
    let(:firebase_release_info) do
      {
        displayVersion: '28.7',
        buildVersion: '1287003',
        testingUri: 'https://appdistribution.firebase.google.com/testerapps/1:123456:ios:abcdef/releases/xyz',
        firebaseConsoleUri: 'https://console.firebase.google.com/project/apps-test/appdistribution/app/ios:com.example.myapp/releases/xyz'
      }
    end

    before do
      stub_const('Fastlane::Actions::SharedValues::FIREBASE_APP_DISTRO_RELEASE', :firebase_app_distro_release)
      allow(Fastlane::Actions).to receive(:lane_context).and_return({ firebase_app_distro_release: firebase_release_info })
    end

    it 'extracts metadata from Firebase release info' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App'
      )
      expect(comment).to include '<td><b>Version</b></td><td>28.7</td>'
      expect(comment).to include '<td><b>Build Number</b></td><td>1287003</td>'
      expect(comment).to include '<td><b>Bundle ID</b></td><td>com.example.myapp</td>'
      expect(comment).to include '<td><b>Installation URL</b></td><td><a href=\'https://appdistribution.firebase.google.com/testerapps/1:123456:ios:abcdef/releases/xyz\'>xyz</a></td>'
    end

    it 'generates QR code for Firebase testing URL' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App'
      )
      expect(comment).to include 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&qzone=4&data=https%3A%2F%2Fappdistribution.firebase.google.com%2Ftesterapps%2F1%3A123456%3Aios%3Aabcdef%2Freleases%2Fxyz'
    end

    it 'includes and prioritizes user-provided metadata over implicit ones' do
      metadata = {
        Version: '42.3',
        'Build Number': '4203008',
        'Build Config': 'Prototype'
      }
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        metadata: metadata
      )
      expect(comment).to include '<td><b>Version</b></td><td>42.3</td>' # explicitly provided, overriding the implicit value
      expect(comment).not_to include '<td><b>Version</b></td><td>28.7</td>' # otherwise implicitly added if it were not overridden
      expect(comment).to include '<td><b>Build Number</b></td><td>4203008</td>' # explicitly provided, overriding the implicit value
      expect(comment).not_to include '<td><b>Build Number</b></td><td>1287003</td>' # otherwise implicitly added if it were not overridden
      expect(comment).to include '<td><b>Build Config</b></td><td>Prototype</td>' # not overriding any implicit one
      # Additional inferred metadata rows: App Name, Bundle ID, Commit, Installation URL
      expect(comment).to include "<td rowspan='7'"
    end

    it 'includes both explicit and implicit metadata when some are provided by the user' do
      metadata = {
        'Version:Short': '28.1',
        'Version:Long': '281003',
        'Build Config': 'Prototype'
      }
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        metadata: metadata
      )
      expect(comment).to include '<td><b>App Name</b></td><td>My App</td>'
      expect(comment).to include '<td><b>Version:Short</b></td><td>28.1</td>'
      expect(comment).to include '<td><b>Version:Long</b></td><td>281003</td>'
      expect(comment).to include '<td><b>Build Config</b></td><td>Prototype</td>'
      expect(comment).to include '<td><b>Bundle ID</b></td><td>com.example.myapp</td>'
      expect(comment).to include '<td><b>Commit</b></td><td>a1b2c3f</td>'
      expect(comment).to include "<td><b>Installation URL</b></td><td><a href='https://appdistribution.firebase.google.com/testerapps/1:123456:ios:abcdef/releases/xyz'>xyz</a></td>"
      # Additional inferred metadata rows: Build Number, Version
      expect(comment).to include "<td rowspan='9'"
    end

    describe 'platform-specific labels' do
      context 'when using Android' do
        let(:firebase_release_info) do
          {
            displayVersion: '28.7',
            buildVersion: '1287003',
            testingUri: 'https://appdistribution.firebase.google.com/testerapps/1:123456:android:abcdef/releases/xyz',
            firebaseConsoleUri: 'https://console.firebase.google.com/project/apps-test/appdistribution/app/android:com.example.myapp/releases/xyz'
          }
        end

        it 'uses "Application ID" as the name for the bundle identifier' do
          comment = run_described_fastlane_action(
            app_display_name: 'My App'
          )
          expect(comment).to include '<td><b>Application ID</b></td><td>com.example.myapp</td>'
          expect(comment).not_to include 'Bundle ID'
        end
      end

      context 'when using iOS' do
        let(:firebase_release_info) do
          {
            displayVersion: '28.7',
            buildVersion: '1287003',
            testingUri: 'https://appdistribution.firebase.google.com/testerapps/1:123456:ios:abcdef/releases/xyz',
            firebaseConsoleUri: 'https://console.firebase.google.com/project/apps-test/appdistribution/app/ios:com.example.myapp/releases/xyz'
          }
        end

        it 'uses "Bundle ID" as the name for the bundle identifier' do
          comment = run_described_fastlane_action(
            app_display_name: 'My App'
          )
          expect(comment).to include '<td><b>Bundle ID</b></td><td>com.example.myapp</td>'
          expect(comment).not_to include 'Application ID'
        end
      end
    end

    describe 'footnote behavior' do
      it 'includes the default Firebase footnote if no explicit footnote is provided' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App'
        )
        expect(comment).to include described_class::DEFAULT_FOOTNOTE
      end

      it 'includes the provided footnote if one was provided explicitly' do
        comment = run_described_fastlane_action(
          app_display_name: 'My App',
          footnote: custom_footnote
        )
        expect(comment).to include custom_footnote
        expect(comment).not_to include described_class::DEFAULT_FOOTNOTE
      end
    end
  end

  context 'when using direct download URL' do
    it 'generates QR code for the direct download URL' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        download_url: 'https://example.com/myapp.apk'
      )
      expect(comment).to include 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&qzone=4&data=https%3A%2F%2Fexample.com%2Fmyapp.apk'
    end

    it 'includes the direct download link in metadata' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        download_url: 'https://example.com/myapp.apk'
      )
      expect(comment).to include "<td><b>Direct Download</b></td><td><a href='https://example.com/myapp.apk'><code>myapp.apk</code></a></td>"
    end

    it 'does not include any default footnote if no explicit footnote is provided' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        download_url: 'https://example.com/myapp.apk'
      )
      expect(comment).not_to include described_class::DEFAULT_FOOTNOTE
    end

    it 'includes the provided footnote if one was provided explicitly' do
      comment = run_described_fastlane_action(
        app_display_name: 'My App',
        download_url: 'https://example.com/myapp.apk',
        footnote: custom_footnote
      )
      expect(comment).to include custom_footnote
    end
  end

  describe 'validating full comment' do
    it 'generates a standard HTML table comment by default' do
      metadata = {
        'Version Name': '28.2',
        'Version Code': '1280200108',
        Flavor: 'Debug'
      }

      comment = run_described_fastlane_action(
        app_display_name: 'The Best App',
        download_url: 'https://example.com/bestapp.apk',
        metadata: metadata
      )

      expect(comment).to eq <<~EXPECTED_COMMENT
        <p><img align='top' src='https://raw.githubusercontent.com/buildkite/emojis/main/img-buildkite-64/firebase.png' width='20px' alt='App Icon' />📲 You can test the changes from this Pull Request in <b>The Best App</b> by scanning the QR code below to install the corresponding build.</p>
        <table>
        <tr>
          <td rowspan='6' width='260px'><img src='https://api.qrserver.com/v1/create-qr-code/?size=500x500&qzone=4&data=https%3A%2F%2Fexample.com%2Fbestapp.apk' width='250' height='250' /></td>
          <td><b>App Name</b></td><td>The Best App</td>
        </tr>
        <tr><td><b>Version Name</b></td><td>28.2</td></tr>
        <tr><td><b>Version Code</b></td><td>1280200108</td></tr>
        <tr><td><b>Flavor</b></td><td>Debug</td></tr>
        <tr><td><b>Commit</b></td><td>a1b2c3f</td></tr>
        <tr><td><b>Direct Download</b></td><td><a href='https://example.com/bestapp.apk'><code>bestapp.apk</code></a></td></tr>
        </table>
      EXPECTED_COMMENT
    end

    it 'generates a HTML table in a spoiler block if fold is true' do
      metadata = {
        'Version Name': '28.2',
        'Version Code': '1280200108'
      }

      comment = run_described_fastlane_action(
        app_display_name: 'The Best App',
        download_url: 'https://example.com/bestapp.apk',
        fold: true,
        metadata: metadata,
        footnote: custom_footnote
      )

      expect(comment).to eq <<~EXPECTED_COMMENT
        <details><summary><img align='top' src='https://raw.githubusercontent.com/buildkite/emojis/main/img-buildkite-64/firebase.png' width='20px' alt='App Icon' />📲 You can test the changes from this Pull Request in <b>The Best App</b> by scanning the QR code below to install the corresponding build.</summary>
        <table>
        <tr>
          <td rowspan='5' width='260px'><img src='https://api.qrserver.com/v1/create-qr-code/?size=500x500&qzone=4&data=https%3A%2F%2Fexample.com%2Fbestapp.apk' width='250' height='250' /></td>
          <td><b>App Name</b></td><td>The Best App</td>
        </tr>
        <tr><td><b>Version Name</b></td><td>28.2</td></tr>
        <tr><td><b>Version Code</b></td><td>1280200108</td></tr>
        <tr><td><b>Commit</b></td><td>a1b2c3f</td></tr>
        <tr><td><b>Direct Download</b></td><td><a href='https://example.com/bestapp.apk'><code>bestapp.apk</code></a></td></tr>
        </table>
        <em>Note: Google Sign-In is not available in those builds</em>
        </details>
      EXPECTED_COMMENT
    end
  end

  describe 'app_icon handling' do
    context 'when providing an URL' do
      it 'includes the icon in the intro text' do
        comment = run_described_fastlane_action(base_params.merge(app_icon: valid_app_icon_url))
        expect(comment).to include "<img align='top' src='#{valid_app_icon_url}' width='20px' alt='App Icon' />📲 "
      end
    end

    context 'when providing an emoji code' do
      it 'includes the icon in the intro text' do
        comment = run_described_fastlane_action(base_params.merge(app_icon: ':jetpack:'))
        expect(comment).to include "<img align='top' src='https://raw.githubusercontent.com/buildkite/emojis/main/img-buildkite-64/jetpack.png' width='20px' alt='App Icon' />📲 "
      end

      it 'handles emoji codes with special characters' do
        comment = run_described_fastlane_action(base_params.merge(app_icon: ':plus-one:'))
        expect(comment).to include 'plus-one.png'
      end
    end

    context 'when no icon is provided' do
      it 'uses the default firebase icon' do
        comment = run_described_fastlane_action(base_params.merge(app_icon: nil))
        expect(comment).to include 'firebase.png'
      end
    end
  end
end
