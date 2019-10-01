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
    expect(Fastlane::Helper::GitHelper.is_git_repo).to be false
  end

  it 'can detect a valid git repository' do
    `git init`
    expect(Fastlane::Helper::GitHelper.is_git_repo).to be true
  end

  it 'can detect a repository with Git-lfs enabled' do
    `git init`
    `git lfs install`
    expect(Fastlane::Helper::GitHelper.has_git_lfs).to be true
  end

  it 'can detect a repository without Git-lfs enabled' do
    `git init`
    `git lfs uninstall &>/dev/null`
    expect(Fastlane::Helper::GitHelper.is_git_repo).to be true
    expect(Fastlane::Helper::GitHelper.has_git_lfs).to be false
  end
end
