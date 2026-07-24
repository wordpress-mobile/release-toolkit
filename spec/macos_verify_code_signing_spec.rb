# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::MacosVerifyCodeSigningAction do
  let(:authority) { 'Developer ID Application: Automattic, Inc. (ABCDE12345)' }

  # Runs the action against artifacts that exist on disk, so that the existence
  # check doesn't get in the way of asserting on the commands the action runs.
  #
  def with_artifacts(*names)
    in_tmp_dir do |tmp_dir|
      paths = names.map do |name|
        path = File.join(tmp_dir, name)
        # A `.app` is a directory and a `.dmg` a file, but the action only calls
        # `File.exist?`, so either satisfies it.
        FileUtils.mkdir_p(path)
        path
      end
      yield(paths)
    end
  end

  def expect_codesign_verify_deep(path, exitstatus: 0, output: '')
    expect_shell_command('codesign', '--verify', '--deep', '--strict', '--verbose=2', path, exitstatus: exitstatus, output: output)
  end

  def expect_codesign_verify(path, exitstatus: 0, output: '')
    expect_shell_command('codesign', '--verify', '--strict', '--verbose=2', path, exitstatus: exitstatus, output: output)
  end

  def expect_codesign_display(path, authority:)
    expect_shell_command('codesign', '--display', '--verbose=2', path, output: "Executable=#{path}\nAuthority=#{authority}\n")
  end

  def expect_gatekeeper_assess_execute(path, exitstatus: 0)
    expect_shell_command('spctl', '--assess', '--type', 'execute', '--verbose=2', path, exitstatus: exitstatus)
  end

  def expect_gatekeeper_assess_open(path, exitstatus: 0)
    expect_shell_command('spctl', '--assess', '--type', 'open', '--context', 'context:primary-signature', '--verbose=2', path, exitstatus: exitstatus)
  end

  def expect_stapler_validate(path, exitstatus: 0)
    expect_shell_command('xcrun', 'stapler', 'validate', path, exitstatus: exitstatus)
  end

  before do
    allow_fastlane_action_sh
  end

  describe 'app bundles' do
    it 'verifies the signature, Gatekeeper acceptance and stapled ticket' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path)
        expect_gatekeeper_assess_execute(path)
        expect_stapler_validate(path)

        run_described_fastlane_action(artifact_path: path)
      end
    end

    it 'skips the notarization checks when `verify_notarization` is `false`' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path)
        expect(Open3).not_to receive(:popen2e).with('spctl', any_args)
        expect(Open3).not_to receive(:popen2e).with('xcrun', any_args)

        run_described_fastlane_action(artifact_path: path, verify_notarization: false)
      end
    end

    it 'passes when signed by the expected authority' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path)
        expect_codesign_display(path, authority: authority)
        expect_gatekeeper_assess_execute(path)
        expect_stapler_validate(path)

        run_described_fastlane_action(artifact_path: path, expected_authority: authority)
      end
    end

    it 'fails when signed by a different authority' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path)
        expect_codesign_display(path, authority: 'Apple Development: Someone Else (ZZZZZ99999)')

        expect { run_described_fastlane_action(artifact_path: path, expected_authority: authority) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /is not signed by '#{Regexp.escape(authority)}'/)
      end
    end

    it 'fails when the signature is not valid' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path, exitstatus: 1, output: "#{path}: invalid signature (code or signature have been modified)\n")

        expect { run_described_fastlane_action(artifact_path: path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /The code signature of .*Test\.app is not valid/)
      end
    end

    # Unlike a disk image, an app bundle without a signature is always a failure.
    it 'fails when it is not signed at all' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path, exitstatus: 1, output: "#{path}: code object is not signed at all\n")

        expect { run_described_fastlane_action(artifact_path: path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /Test\.app is not signed at all/)
      end
    end

    it 'fails when Gatekeeper rejects it' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path)
        expect_gatekeeper_assess_execute(path, exitstatus: 3)

        expect { run_described_fastlane_action(artifact_path: path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /Test\.app was rejected by Gatekeeper/)
      end
    end

    it 'fails when it has no notarization ticket stapled' do
      with_artifacts('Test.app') do |(path)|
        expect_codesign_verify_deep(path)
        expect_gatekeeper_assess_execute(path)
        expect_stapler_validate(path, exitstatus: 65)

        expect { run_described_fastlane_action(artifact_path: path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /Test\.app has no notarization ticket stapled to it/)
      end
    end
  end

  describe 'disk images' do
    # `electron-builder` signs the app inside the image but not the image itself,
    # which is what our own `.dmg` artifacts look like.
    it 'checks only the stapled ticket when the image is not signed' do
      with_artifacts('Test.dmg') do |(path)|
        expect_codesign_verify(path, exitstatus: 1, output: "#{path}: code object is not signed at all\n")
        expect_stapler_validate(path)
        expect(Open3).not_to receive(:popen2e).with('spctl', any_args)
        expect(FastlaneCore::UI).to receive(:important).with(/is not signed — skipping its signature checks/)

        run_described_fastlane_action(artifact_path: path)
      end
    end

    it 'does not assert the authority of an unsigned image' do
      with_artifacts('Test.dmg') do |(path)|
        expect_codesign_verify(path, exitstatus: 1, output: "#{path}: code object is not signed at all\n")
        expect_stapler_validate(path)
        expect(Open3).not_to receive(:popen2e).with('codesign', '--display', any_args)

        run_described_fastlane_action(artifact_path: path, expected_authority: authority)
      end
    end

    it 'checks Gatekeeper and the authority when the image is signed' do
      with_artifacts('Test.dmg') do |(path)|
        expect_codesign_verify(path)
        expect_codesign_display(path, authority: authority)
        expect_gatekeeper_assess_open(path)
        expect_stapler_validate(path)

        run_described_fastlane_action(artifact_path: path, expected_authority: authority)
      end
    end

    it 'fails when the image carries a broken signature' do
      with_artifacts('Test.dmg') do |(path)|
        expect_codesign_verify(path, exitstatus: 1, output: "#{path}: invalid signature (code or signature have been modified)\n")

        expect { run_described_fastlane_action(artifact_path: path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /The code signature of .*Test\.dmg is not valid/)
      end
    end

    it 'fails when it has no notarization ticket stapled' do
      with_artifacts('Test.dmg') do |(path)|
        expect_codesign_verify(path, exitstatus: 1, output: "#{path}: code object is not signed at all\n")
        expect_stapler_validate(path, exitstatus: 65)

        expect { run_described_fastlane_action(artifact_path: path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /Test\.dmg has no notarization ticket stapled to it/)
      end
    end

    it 'skips every check but the signature when `verify_notarization` is `false`' do
      with_artifacts('Test.dmg') do |(path)|
        expect_codesign_verify(path)
        expect(Open3).not_to receive(:popen2e).with('spctl', any_args)
        expect(Open3).not_to receive(:popen2e).with('xcrun', any_args)

        run_described_fastlane_action(artifact_path: path, verify_notarization: false)
      end
    end
  end

  it 'verifies every artifact when given a list of paths' do
    with_artifacts('One.app', 'Two.dmg') do |(app_path, dmg_path)|
      expect_codesign_verify_deep(app_path)
      expect_gatekeeper_assess_execute(app_path)
      expect_stapler_validate(app_path)

      expect_codesign_verify(dmg_path, exitstatus: 1, output: "#{dmg_path}: code object is not signed at all\n")
      expect_stapler_validate(dmg_path)

      run_described_fastlane_action(artifact_path: [app_path, dmg_path])
    end
  end

  it 'fails on an artifact it does not know how to verify' do
    with_artifacts('Test.zip') do |(path)|
      expect { run_described_fastlane_action(artifact_path: path) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Don't know how to verify .*Test\.zip/)
    end
  end

  it 'fails when there is no artifact at the given path' do
    expect { run_described_fastlane_action(artifact_path: '/path/to/Missing.app') }
      .to raise_error(FastlaneCore::Interface::FastlaneError, %r{There is no artifact at /path/to/Missing\.app})
  end

  it 'fails when given an empty list of paths' do
    expect { run_described_fastlane_action(artifact_path: []) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /`artifact_path` is empty/)
  end

  it 'fails when `artifact_path` is neither a String nor an Array' do
    expect { run_described_fastlane_action(artifact_path: 42) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /`artifact_path` must be a String or an Array of Strings/)
  end

  it 'fails when `artifact_path` is an Array of something other than Strings' do
    expect { run_described_fastlane_action(artifact_path: [42]) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /`artifact_path` must be a String or an Array of Strings/)
  end
end
