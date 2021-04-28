require 'tmpdir'
require_relative './spec_helper'

describe Fastlane::Helper::GitHelper do
  before(:each) do
    @path = Dir.mktmpdir
    @tmp = Dir.pwd
    Dir.chdir(@path)
  end

  after(:each) do
    Dir.chdir(@tmp)
    FileUtils.rm_rf(@path)
  end

  it 'can detect a missing git repository' do
    expect(Fastlane::Helper::GitHelper.is_git_repo?).to be false
  end

  it 'can detect a valid git repository' do
    `git init`
    expect(Fastlane::Helper::GitHelper.is_git_repo?).to be true
  end

  it 'can detect a repository with Git-lfs enabled' do
    `git init`
    `git lfs install`
    expect(Fastlane::Helper::GitHelper.has_git_lfs?).to be true
  end

  it 'can detect a repository without Git-lfs enabled' do
    `git init`
    `git lfs uninstall &>/dev/null`
    expect(Fastlane::Helper::GitHelper.is_git_repo?).to be true
    expect(Fastlane::Helper::GitHelper.has_git_lfs?).to be false
  end

  context('commit(message:, files:, push:)') do
    before(:each) do
      allow_fastlane_action_sh()
      @message = 'Some commit message with spaces'
    end

    it 'commits without adding any file if none are provided' do
      expect_shell_command('git', 'add', any_args).never
      expect_shell_command('git', 'commit', '-m', @message)
      Fastlane::Helper::GitHelper.commit(message: @message)
    end

    it 'commits without adding any file if nil is provided' do
      expect_shell_command('git', 'add', any_args).never
      expect_shell_command('git', 'commit', '-m', @message)
      Fastlane::Helper::GitHelper.commit(message: @message, files: nil)
    end

    it 'commits without adding any file if an empty list of files is provided' do
      expect_shell_command('git', 'add', any_args).never
      expect_shell_command('git', 'commit', '-m', @message)
      Fastlane::Helper::GitHelper.commit(message: @message, files: [])
    end

    it 'adds a single file before commit if a single String is provided as `files`' do
      file = 'some file'
      expect_shell_command('git', 'add', file)
      expect_shell_command('git', 'commit', '-m', @message)
      Fastlane::Helper::GitHelper.commit(message: @message, files: file)
    end

    it 'adds multiple files before commit if an Array is provided as `files`' do
      files = ['file 1', 'file 2', 'file 3']
      expect_shell_command('git', 'add', files[0], files[1], files[2])
      expect_shell_command('git', 'commit', '-m', @message)
      Fastlane::Helper::GitHelper.commit(message: @message, files: files)
    end

    it 'adds all pending file changes before commit if :all is provided as `files`' do
      expect_shell_command('git', 'commit', '-a', '-m', @message)
      Fastlane::Helper::GitHelper.commit(message: @message, files: :all)
    end

    it 'does not push to origin if not asked' do
      expect_shell_command('git', 'commit', '-m', @message)
      expect_shell_command('git', 'push', any_args).never
      Fastlane::Helper::GitHelper.commit(message: @message)
    end

    it 'does push to origin if asked' do
      expect_shell_command('git', 'commit', '-m', @message)
      expect_shell_command('git', 'push', 'origin', 'HEAD').once
      Fastlane::Helper::GitHelper.commit(message: @message, push: true)
    end

    describe '#is_ignored?' do
      context 'when the path is not ignored' do
        it 'returns false' do
          path = 'dummy.txt'
          setup_git_repo(
            dummy_file_path: path,
            in_gitignore: false
          )
          expect(Fastlane::Helper::GitHelper.is_ignored?(path: path)).to be false
        end
      end

      context 'when the path is in the .gitignore' do
        context "but the .gitignore change hasn't been committed" do
          # For some reason, I was expecting the underlying `git check-ignore`
          # command to fail in this case, but I'm clearly wrong.
          #
          # I think there's value in keeping this behavior explicity documented
          # and verified here. – Gio
          it 'returns true' do
            path = 'dummy.txt'
            setup_git_repo(
              dummy_file_path: path,
              in_gitignore: true,
              gitignore_committed: false
            )
            expect(Fastlane::Helper::GitHelper.is_ignored?(path: path)).to be false
          end
        end

        it 'returns true' do
          path = 'dummy.txt'
          setup_git_repo(
            dummy_file_path: path,
            in_gitignore: true,
            gitignore_committed: true
          )
          expect(Fastlane::Helper::GitHelper.is_ignored?(path: path)).to be true
        end
      end
    end
  end
end

private
def setup_git_repo(dummy_file_path:, in_gitignore:, gitignore_committed: false)
  `git init`
  `echo abc > #{dummy_file_path}`

  # no point in commiting the gitignore if the file shouldn't be in it
  return unless in_gitignore

  `echo #{dummy_file_path} > .gitignore`
  `git add .gitignore && git commit -m 'Add .gitignore'` if gitignore_committed

  puts `git check-ignore #{dummy_file_path}`
end
