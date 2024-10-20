require 'tmpdir'
require_relative 'spec_helper'

describe Fastlane::Helper::GitHelper do
  before do
    @path = Dir.mktmpdir
    @tmp = Dir.pwd
    Dir.chdir(@path)

    allow(FastlaneCore::Helper).to receive(:sh_enabled?).and_return(true)
  end

  after do
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
    init_git_repo
    expect(described_class.is_git_repo?).to be true
  end

  it 'can detect a valid git repository from a child folder' do
    init_git_repo
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
    init_git_repo
    `git lfs install`
    expect(described_class.has_git_lfs?).to be true
  end

  it 'can detect a repository without Git-lfs enabled' do
    init_git_repo
    `git lfs uninstall &>/dev/null`
    expect(described_class.is_git_repo?).to be true
    expect(described_class.has_git_lfs?).to be false
  end

  describe 'commit(message:, files:)' do
    before do
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

  describe 'point_to_same_commit?(ref1, ref2)' do
    # We cannot test the happy path using a remote because the repo we use for the tests does not have a remote.
    let(:remote_name) { nil }

    before do
      # Spec branching setup:
      #
      #   (1.0)
      # A---B---C----G   main
      #        / \  /
      #       |   D      feature-branch
      #       |
      #       E---F      another-branch / new-branch

      init_git_repo

      add_file_and_commit(file: 'file1.txt', message: 'commit A')
      add_file_and_commit(file: 'file2.txt', message: 'commit B')

      create_tag('1.0')

      add_file_and_commit(file: 'file3.txt', message: 'commit C')

      create_branch('feature-branch')
      add_file_and_commit(file: 'file4.txt', message: 'commit D feature branch')

      checkout_branch('main')

      create_branch('another-branch')
      add_file_and_commit(file: 'file5.txt', message: 'commit E another branch')
      add_file_and_commit(file: 'file6.txt', message: 'commit F another branch')

      create_branch('new-branch')

      merge_branch(base: 'main', head: 'feature-branch')
    end

    it 'checks if a tag and a branch point to the same commit' do
      same_commit = described_class.point_to_same_commit?('1.0', 'another-branch', remote_name: remote_name)
      expect(same_commit).to be false
    end

    it 'checks if a tag and a branch that had a merge point to the same commit' do
      same_commit = described_class.point_to_same_commit?('1.0', 'main', remote_name: remote_name)
      expect(same_commit).to be false
    end

    it 'checks if a tag and a commit hash point to the same commit' do
      same_commit = described_class.point_to_same_commit?('1.0', commit_hash(commit_message: 'commit D'), remote_name: remote_name)
      expect(same_commit).to be false
    end

    it 'checks if a commit hash and a branch point to the same commit' do
      same_commit = described_class.point_to_same_commit?(commit_hash(commit_message: 'commit B'), 'another-branch', remote_name: remote_name)
      expect(same_commit).to be false
    end

    it 'checks if commits between the same branch point to the same commit' do
      same_commit = described_class.point_to_same_commit?('feature-branch', 'feature-branch', remote_name: remote_name)
      expect(same_commit).to be true
    end

    it 'checks if commits between branches that have no difference point to the same commit' do
      same_commit = described_class.point_to_same_commit?('another-branch', 'new-branch', remote_name: remote_name)
      expect(same_commit).to be true
    end

    it 'raises error for a non-existent base_ref' do
      expect { described_class.point_to_same_commit?('non-existent', 'main', remote_name: remote_name) }.to raise_error(StandardError)
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
  init_git_repo
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

def init_git_repo
  `git init --initial-branch main || git init`
end

def add_file_and_commit(file:, message:)
  `touch #{file}`
  `git add .`
  `git commit -m '#{message}'`
end

def checkout_branch(branch_name)
  `git checkout #{branch_name}`
end

def create_branch(branch_name)
  `git checkout -B #{branch_name}`
end

def merge_branch(base:, head:)
  checkout_branch(base)

  `git merge --no-ff #{head}`
end

def create_tag(tag_name)
  `git tag #{tag_name}`
end

def commit_hash(commit_message:)
  `git log --pretty=format:'%H' -1 --grep='#{commit_message}'`.strip
end
