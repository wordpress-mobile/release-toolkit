require_relative './spec_helper'

describe Fastlane::Actions::PrototypeBuildDetailsCommentAction do
  before do
    ENV['APPCENTER_OWNER_NAME'] = 'My-Org'
    ENV['BUILDKITE_COMMIT'] = 'a1b2c3f'
  end

  describe 'expected info is included' do
    it 'generates the proper AppCenter link and QR code given an org, app name and release ID' do
      comment = run_described_fastlane_action(
        appcenter_app_name: 'MyApp',
        appcenter_release_id: 1337
      )
      expect(comment).to include "<a href='https://install.appcenter.ms/orgs/My-Org/apps/MyApp/releases/1337'>Build #1337</a>"
      expect(comment).to include 'https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FMy-Org%2Fapps%2FMyApp%2Freleases%2F1337&choe=UTF-8'
    end

    it 'includes the commit as part of the default rows' do
      comment = run_described_fastlane_action(
        appcenter_app_name: 'MyApp',
        appcenter_release_id: 1337
      )
      expect(comment).to include '<td><b>Commit</b></td><td><tt>a1b2c3f</tt></td>'
    end

    it 'correctly includes additional metadata when some are provided' do
      metadata = {
        'Version:Short': '28.1',
        'Version:Long': '281003',
        'Build Config': 'Prototype'
      }
      comment = run_described_fastlane_action(
        appcenter_app_name: 'MyApp',
        appcenter_release_id: 1337,
        metadata: metadata
      )
      expect(comment).to include "<td rowspan='6'>"
      expect(comment).to include '<td><b>Version:Short</b></td><td>28.1</td>'
      expect(comment).to include '<td><b>Version:Long</b></td><td>281003</td>'
      expect(comment).to include '<td><b>Build Config</b></td><td>Prototype</td>'
    end

    it 'includes the direct link if one is provided' do
      comment = run_described_fastlane_action(
        appcenter_app_name: 'MyApp',
        appcenter_release_id: 1337,
        download_url: 'https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'
      )
      expect(comment).to include "<td rowspan='4'>"
      expect(comment).to include "<td><b>Direct Link</b></td><td><a href='https://foo.cloudfront.net/someuuid/myapp-prototype-build-pr1337-a1b2c3f.apk'><tt>myapp-prototype-build-pr1337-a1b2c3f.apk</tt></a></td>"
    end

    it 'includes the default footnote by default' do
      comment = run_described_fastlane_action(
        appcenter_org_name: 'BestOrg',
        appcenter_app_name: 'MyApp',
        appcenter_release_id: 1337
      )
      expect(comment).to include '<em>Automatticians: You can use our internal self-serve MC tool to give yourself access to App Center if needed.</em>'
    end

    it 'includes the provided footnote if any' do
      comment = run_described_fastlane_action(
        appcenter_app_name: 'MyApp',
        appcenter_release_id: 1337,
        footnote: '<em>Note that Google Sign-In in not available in those builds</em>'
      )
      expect(comment).to include '<em>Note that Google Sign-In in not available in those builds</em>'
    end
  end

  describe 'full comment' do
    it 'generates a standard HTML table comment by default, with all the information provided' do
      metadata = {
        'Version:Short': '28.2',
        'Version:Long': '28.2.0.108',
        Flavor: 'Celray'
      }

      comment = run_described_fastlane_action(
        appcenter_org_name: 'BestOrg',
        appcenter_app_name: 'BestApp',
        appcenter_release_id: 8888,
        metadata: metadata,
        footnote: '<em>Note: Google Sign-In in not available in those builds</em>'
      )

      expect(comment).to eq <<~EXPECTED_COMMENT
        <p>📲 You can test the changes from this Pull Request by scanning the QR code below with your phone to install the corresponding <strong>BestApp</strong> build from App Center.</p>
        <table>
        <tr>
          <td rowspan='6'><img src='https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FBestOrg%2Fapps%2FBestApp%2Freleases%2F8888&choe=UTF-8' width='250' height='250' /></td>
          <td width='150px'><b>App</b></td><td><tt>BestApp</tt></td>
        </tr>
        <tr><td><b>Version:Short</b></td><td>28.2</td></tr>
        <tr><td><b>Version:Long</b></td><td>28.2.0.108</td></tr>
        <tr><td><b>Flavor</b></td><td>Celray</td></tr>
        <tr><td><b>App Center Build</b></td><td><a href='https://install.appcenter.ms/orgs/BestOrg/apps/BestApp/releases/8888'>Build \#8888</a></td></tr>
        <tr><td><b>Commit</b></td><td><tt>a1b2c3f</tt></td></tr>
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
        appcenter_org_name: 'BestOrg',
        appcenter_app_name: 'BestApp',
        appcenter_release_id: 8888,
        download_url: 'https://bestfront.cloudfront.net/feed42/bestapp-pr1357-a1b2c3f.apk',
        metadata: metadata
      )

      expect(comment).to eq <<~EXPECTED_COMMENT
        <p>📲 You can test the changes from this Pull Request by scanning the QR code below with your phone to install the corresponding <strong>BestApp</strong> build from App Center.</p>
        <table>
        <tr>
          <td rowspan='6'><img src='https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FBestOrg%2Fapps%2FBestApp%2Freleases%2F8888&choe=UTF-8' width='250' height='250' /></td>
          <td width='150px'><b>App</b></td><td><tt>BestApp</tt></td>
        </tr>
        <tr><td><b>Version:Short</b></td><td>28.2</td></tr>
        <tr><td><b>Version:Long</b></td><td>28.2.0.108</td></tr>
        <tr><td><b>Direct Link</b></td><td><a href='https://bestfront.cloudfront.net/feed42/bestapp-pr1357-a1b2c3f.apk'><tt>bestapp-pr1357-a1b2c3f.apk</tt></a></td></tr>
        <tr><td><b>App Center Build</b></td><td><a href='https://install.appcenter.ms/orgs/BestOrg/apps/BestApp/releases/8888'>Build \#8888</a></td></tr>
        <tr><td><b>Commit</b></td><td><tt>a1b2c3f</tt></td></tr>
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
        appcenter_org_name: 'BestOrg',
        appcenter_app_name: 'BestApp',
        appcenter_release_id: 1234,
        fold: true,
        metadata: metadata,
        footnote: '<em>Note: Google Sign-In in not available in those builds</em>'
      )

      expect(comment).to eq <<~EXPECTED_COMMENT
        <details><summary>📲 You can test the changes from this Pull Request by scanning the QR code below with your phone to install the corresponding <strong>BestApp</strong> build from App Center.</summary>
        <table>
        <tr>
          <td rowspan='7'><img src='https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=https%3A%2F%2Finstall.appcenter.ms%2Forgs%2FBestOrg%2Fapps%2FBestApp%2Freleases%2F1234&choe=UTF-8' width='250' height='250' /></td>
          <td width='150px'><b>App</b></td><td><tt>BestApp</tt></td>
        </tr>
        <tr><td><b>Version:Short</b></td><td>28.2</td></tr>
        <tr><td><b>Version:Long</b></td><td>28.2.0.108</td></tr>
        <tr><td><b>Flavor</b></td><td>Celray</td></tr>
        <tr><td><b>Configuration</b></td><td>Debug</td></tr>
        <tr><td><b>App Center Build</b></td><td><a href='https://install.appcenter.ms/orgs/BestOrg/apps/BestApp/releases/1234'>Build \#1234</a></td></tr>
        <tr><td><b>Commit</b></td><td><tt>a1b2c3f</tt></td></tr>
        </table>
        <em>Note: Google Sign-In in not available in those builds</em>
        </details>
      EXPECTED_COMMENT
    end
  end
end
