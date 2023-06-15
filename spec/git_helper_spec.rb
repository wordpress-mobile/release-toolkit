require 'tmpdir'
require_relative './spec_helper'

describe Fastlane::Helper::GitHelper do
  before(:each) do
    @path = Dir.mktmpdir
    @tmp = Dir.pwd
    Dir.chdir(@path)

    allow(FastlaneCore::Helper).to receive(:sh_enabled?).and_return(true)
  end

  after(:each) do
    Dir.chdir(@tmp)
    FileUtils.rm_rf(@path)
  end

  it 'can detect a missing git repository' do
    expect(described_class.is_git_repo?).to be false
  end

  it 'can detect a missing git repository when given a path' do
    Dir.mktmpdir do |dir|
      expect(described_class.is_git_repo?(path: dir)).to be false
    end
  end

  it 'can detect a valid git repository' do
    `git init --initial-branch main || git init`
    expect(described_class.is_git_repo?).to be true
  end

  it 'can detect a valid git repository from a child folder' do
    `git init --initial-branch main || git init`
    `mkdir -p a/b`
    Dir.chdir('./a/b')
    expect(described_class.is_git_repo?).to be true
  end

  it 'can detect a valid git repository when given a path' do
    Dir.mktmpdir do |dir|
      `git -C #{dir} init --initial-branch main || git -C #{dir} init`
      expect(described_class.is_git_repo?(path: dir)).to be true
    end
  end

  it 'can detect a valid git repository when given a child folder path' do
    Dir.mktmpdir do |dir|
      `git -C #{dir} init --initial-branch main || git -C #{dir} init`
      path = File.join(dir, 'a', 'b')
      `mkdir -p #{path}`
      expect(described_class.is_git_repo?(path: path)).to be true
    end
  end

  it 'can detect a repository with Git-lfs enabled' do
    `git init --initial-branch main || git init`
    `git lfs install`
    expect(described_class.has_git_lfs?).to be true
  end

  it 'can detect a repository without Git-lfs enabled' do
    `git init --initial-branch main || git init`
    `git lfs uninstall &>/dev/null`
    expect(described_class.is_git_repo?).to be true
    expect(described_class.has_git_lfs?).to be false
  end

  context('commit(message:, files:)') do
    before(:each) do
      allow_fastlane_action_sh
      @message = 'Some commit message with spaces'
    end

    it 'commits without adding any file if none are provided' do
      expect_shell_command('git', 'add', any_args).never
      expect_shell_command('git', 'commit', '-m', @message)
      described_class.commit(message: @message)
    end

    it 'commits without adding any file if nil is provided' do
      expect_shell_command('git', 'add', any_args).never
      expect_shell_command('git', 'commit', '-m', @message)
      described_class.commit(message: @message, files: nil)
    end

    it 'commits without adding any file if an empty list of files is provided' do
      expect_shell_command('git', 'add', any_args).never
      expect_shell_command('git', 'commit', '-m', @message)
      described_class.commit(message: @message, files: [])
    end

    it 'adds a single file before commit if a single String is provided as `files`' do
      file = 'some file'
      expect_shell_command('git', 'add', file)
      expect_shell_command('git', 'commit', '-m', @message)
      described_class.commit(message: @message, files: file)
    end

    it 'adds multiple files before commit if an Array is provided as `files`' do
      files = ['file 1', 'file 2', 'file 3']
      expect_shell_command('git', 'add', files[0], files[1], files[2])
      expect_shell_command('git', 'commit', '-m', @message)
      described_class.commit(message: @message, files: files)
    end

    it 'adds all pending file changes before commit if :all is provided as `files`' do
      expect_shell_command('git', 'commit', '-a', '-m', @message)
      described_class.commit(message: @message, files: :all)
    end
  end

  describe '#is_ignored?' do
    let(:path) { 'dummy.txt' }

    it 'returns false when the path is not ignored' do
      setup_git_repo(
        dummy_file_path: path,
        add_file_to_gitignore: false
      )
      expect(described_class.is_ignored?(path: path)).to be false
    end

    context 'when the path is in the .gitignore' do
      it 'returns true when the .gitignore has uncommitted changes' do
        # For some reason, I was expecting the underlying `git check-ignore` command to fail in this case, but I'm clearly wrong.
        #
        # I think there's value in keeping this behavior explicity documented and verified here.
        # – Gio
        setup_git_repo(
          dummy_file_path: path,
          add_file_to_gitignore: true,
          commit_gitignore: false
        )
        expect(described_class.is_ignored?(path: path)).to be true
      end

      it 'returns true when the .gitignore has no uncommitted changes' do
        setup_git_repo(
          dummy_file_path: path,
          add_file_to_gitignore: true,
          commit_gitignore: true
        )
        expect(described_class.is_ignored?(path: path)).to be true
      end
    end

    # This test ensures we support the usecase of the `configure` tool, which can create new files by decrypting secrets.
    # We need the ability to tell if a path result is ignored, regardless of whether it exists yet.
    it 'returns false for files not yet created but part of the repository' do
      setup_git_repo
      expect(described_class.is_ignored?(path: path)).to be false
    end

    it 'returns true when the path is outside the repository folder' do
      # This path is in the parent directory, which is not a Git repo
      path = File.join(@path, '..', 'dummy.txt')

      setup_git_repo(dummy_file_path: path, add_file_to_gitignore: false)
      expect(described_class.is_ignored?(path: path)).to be true
    end

    # This is sort of redundant given the previous example already ensures the same logic.
    # But, we'll be using paths starting with `~` as part of our configurations, so it felt appopriate to explicitly ensure this important use case is respected.
    it 'returns true when the path is in the home folder ' do
      path = '~/a/path'
      expect(described_class.is_ignored?(path: path)).to be true
    end
  end
end

def setup_git_repo(dummy_file_path: nil, add_file_to_gitignore: false, commit_gitignore: false)
  `git init --initial-branch main || git init`
  `touch .gitignore`
  `git add .gitignore && git commit -m 'Add .gitignore'`

  # If we don't have a path for the file, we don't care the values of the two flag arguments are irrelevant.
  # We can just finish here.
  return if dummy_file_path.nil?

  `echo abc > #{dummy_file_path}`

  # no point in commiting the gitignore if the file shouldn't be in it
  return unless add_file_to_gitignore

  `echo #{dummy_file_path} > .gitignore`
  `git add .gitignore && git commit -m 'Update .gitignore'` if commit_gitignore
end
