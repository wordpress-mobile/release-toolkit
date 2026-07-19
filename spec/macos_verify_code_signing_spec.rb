# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::MacosVerifyCodeSigningAction do
  let(:authority) { 'Developer ID Application: Automattic, Inc. (ABCDE12345)' }

  # Runs the action against `.app` paths that exist on disk, so that the existence
  # check doesn't get in the way of asserting on the commands the action runs.
  #
  def with_app_bundles(*names)
    in_tmp_dir do |tmp_dir|
      paths = names.map do |name|
        path = File.join(tmp_dir, name)
        FileUtils.mkdir_p(path)
        path
      end
      yield(paths)
    end
  end

  def expect_codesign_verify(app_path, exitstatus: 0)
    expect_shell_command('codesign', '--verify', '--deep', '--strict', '--verbose=2', app_path, exitstatus: exitstatus)
  end

  def expect_codesign_display(app_path, authority:)
    expect_shell_command('codesign', '--display', '--verbose=2', app_path, output: "Executable=#{app_path}\nAuthority=#{authority}\n")
  end

  def expect_gatekeeper_assess(app_path, exitstatus: 0)
    expect_shell_command('spctl', '--assess', '--type', 'execute', '--verbose=2', app_path, exitstatus: exitstatus)
  end

  def expect_stapler_validate(app_path, exitstatus: 0)
    expect_shell_command('xcrun', 'stapler', 'validate', app_path, exitstatus: exitstatus)
  end

  before do
    allow_fastlane_action_sh
  end

  it 'verifies the signature, Gatekeeper acceptance and stapled ticket of a single app' do
    with_app_bundles('Test.app') do |(app_path)|
      expect_codesign_verify(app_path)
      expect_gatekeeper_assess(app_path)
      expect_stapler_validate(app_path)

      run_described_fastlane_action(app_path: app_path)
    end
  end

  it 'verifies every app when given a list of paths' do
    with_app_bundles('One.app', 'Two.app') do |paths|
      paths.each do |app_path|
        expect_codesign_verify(app_path)
        expect_gatekeeper_assess(app_path)
        expect_stapler_validate(app_path)
      end

      run_described_fastlane_action(app_path: paths)
    end
  end

  it 'skips the notarization checks when `verify_notarization` is `false`' do
    with_app_bundles('Test.app') do |(app_path)|
      expect_codesign_verify(app_path)
      expect(Open3).not_to receive(:popen2e).with('spctl', any_args)
      expect(Open3).not_to receive(:popen2e).with('xcrun', any_args)

      run_described_fastlane_action(app_path: app_path, verify_notarization: false)
    end
  end

  it 'passes when the app is signed by the expected authority' do
    with_app_bundles('Test.app') do |(app_path)|
      expect_codesign_verify(app_path)
      expect_codesign_display(app_path, authority: authority)
      expect_gatekeeper_assess(app_path)
      expect_stapler_validate(app_path)

      run_described_fastlane_action(app_path: app_path, expected_authority: authority)
    end
  end

  it 'fails when the app is signed by a different authority' do
    with_app_bundles('Test.app') do |(app_path)|
      expect_codesign_verify(app_path)
      expect_codesign_display(app_path, authority: 'Apple Development: Someone Else (ZZZZZ99999)')

      expect { run_described_fastlane_action(app_path: app_path, expected_authority: authority) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /is not signed by '#{Regexp.escape(authority)}'/)
    end
  end

  it 'fails when the signature is not valid' do
    with_app_bundles('Test.app') do |(app_path)|
      expect_codesign_verify(app_path, exitstatus: 1)

      expect { run_described_fastlane_action(app_path: app_path) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /The code signature of .*Test\.app is not valid/)
    end
  end

  it 'fails when Gatekeeper rejects the app' do
    with_app_bundles('Test.app') do |(app_path)|
      expect_codesign_verify(app_path)
      expect_gatekeeper_assess(app_path, exitstatus: 3)

      expect { run_described_fastlane_action(app_path: app_path) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Test\.app was rejected by Gatekeeper/)
    end
  end

  it 'fails when the app has no notarization ticket stapled' do
    with_app_bundles('Test.app') do |(app_path)|
      expect_codesign_verify(app_path)
      expect_gatekeeper_assess(app_path)
      expect_stapler_validate(app_path, exitstatus: 65)

      expect { run_described_fastlane_action(app_path: app_path) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Test\.app has no notarization ticket stapled to it/)
    end
  end

  it 'fails when there is no app at the given path' do
    expect { run_described_fastlane_action(app_path: '/path/to/Missing.app') }
      .to raise_error(FastlaneCore::Interface::FastlaneError, %r{There is no app bundle at /path/to/Missing\.app})
  end

  it 'fails when given an empty list of paths' do
    expect { run_described_fastlane_action(app_path: []) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /`app_path` is empty/)
  end

  it 'fails when `app_path` is neither a String nor an Array' do
    expect { run_described_fastlane_action(app_path: 42) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /`app_path` must be a String or an Array of Strings/)
  end
end
