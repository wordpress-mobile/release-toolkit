# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

describe Fastlane::Helper::ConfigureHelper do
  let(:test_repo_path) { Dir.mktmpdir }

  def run_git_command(command:, repo_path: test_repo_path)
    # Notice that this will break if the command contains arguments in quotes,
    # e.g. `commit -m "Test commit"` will be split into `['commit', '-m', '"Test', 'commit"']`
    # which is not a valid arguments list for Git.
    #
    # For the context of these tests, we can deal with this limitation.
    system('git', '-C', repo_path, *command.split, %I[out err] => File::NULL)
  end

  before do
    allow(described_class).to receive(:repository_path).and_return(test_repo_path)

    run_git_command(command: 'init')
    run_git_command(command: 'config user.email test@example.com')
    run_git_command(command: 'config user.name Test User')
    File.write(File.join(test_repo_path, 'test.txt'), 'test content')
    run_git_command(command: 'add test.txt')
    run_git_command(command: 'commit -m test')
  end

  after do
    FileUtils.remove_entry test_repo_path
  end

  describe '.repo_branch_name' do
    it 'returns the current branch name when on a branch' do
      run_git_command(command: 'checkout -b feature-branch')
      expect(described_class.repo_branch_name).to eq('feature-branch')
    end

    it 'returns nil when in detached HEAD state' do
      current_sha = `git -C #{test_repo_path} rev-parse HEAD`.strip
      run_git_command(command: "checkout #{current_sha}")
      expect(described_class.repo_branch_name).to be_nil
    end
  end

  describe '#add_file' do
    let(:destination) { 'path/to/destination' }

    it 'shows the user an error when the destination is not ignored in Git' do
      in_tmp_dir do
        allow(Fastlane::Helper::GitHelper).to receive(:is_ignored?)
          .with(path: destination)
          .and_return(false)

        # Currently, we need a Git repository to exists in the hierarchy containing the call site otherwise the tests will end up stuck in some kind of loop (which I haven't fully inspected).
        # That's a reasonable enough assumption to make for the real world usage of this tool.
        # Still, it would be nice to have proper handling of that scenario at some point.
        `git init --initial-branch main || git init`

        expect(Fastlane::UI).to receive(:user_error!)

        described_class.add_file(source: 'path/to/source', destination: destination, encrypt: true)
      end
    end
  end
end
