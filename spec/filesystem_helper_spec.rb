require 'tmpdir'
require_relative './spec_helper'

describe Fastlane::Helper::FilesystemHelper do
  before(:each) do
    @temp_path = Dir.mktmpdir
    @previous_path = Dir.pwd
    Dir.chdir(@temp_path)
  end

  after(:each) do
    Dir.chdir(@previous_path)
    FileUtils.rm_rf(@temp_path)
  end

it 'delete_files deletes all files based on given criteria' do
    files_match = ["file_match_1", "file_match_2", "file_match_3", "file_match_4"]

    create_files(files_match)

    files_deleted = Fastlane::Helper::FilesystemHelper.delete_files("file_match_?", false)

    # verify function return value
    expect(files_deleted.sort).to eq files_match.sort

    # verify matching files were deleted
    expect(check_files_exist(files_match, false)).to be true
  end

  it 'delete_files deletes only files based on given criteria' do
    files_match = ["file_match_1", "file_match_2", "file_match_3", "file_match_4"]
    files_no_match = ["file_no_match_1", "file_no_match_2"]

    # add files to temp directory
    create_files(files_match)
    create_files(files_no_match)

    files_deleted = Fastlane::Helper::FilesystemHelper.delete_files("file_match_?", false)

    # verify function return value
    expect(files_deleted.sort).to eq files_match.sort

    # verify matching files were deleted
    expect(check_files_exist(files_match, false)).to be true
    expect(check_files_exist(files_no_match, true)).to be true
  end

  it 'delete_files does not delete files when no files match given criteria' do
    files_no_match = ["file_no_match_1", "file_no_match_2"]

    # add files to temp directory
    create_files(files_no_match)

    files_deleted = Fastlane::Helper::FilesystemHelper.delete_files("file_match_?", false)

    # verify function return value
    expect(files_deleted.empty?).to be true

    # verify non-matching files were not deleted
    expect(check_files_exist(files_no_match, true)).to be true
  end

  it 'delete_files results are empty when no files exist' do
    files_deleted = Fastlane::Helper::FilesystemHelper.delete_files("file_match_?", false)

    # verify function return value
    expect(files_deleted.empty?).to be true
  end
end

def create_files(files_to_create)
  files_to_create.each do |file|
    File.new(file, "w")
  end
end

def check_files_exist(files_to_check, exist)
  files_to_check.each do |file|
    if File.exist?(file) != exist then
      return false
    end
  end
  return true
end