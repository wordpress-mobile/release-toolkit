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

  it 'delete_files can find and delete all and only files based on given criteria' do
    files_match = ["file_match_1", "file_match_2", "file_match_3", "file_match_4"]
    files_no_match = ["file_no_match_1", "file_no_match_2"]

    # add files to temp directory
    files_match.each do |file|
      File.new(file, "w")
    end
    files_no_match.each do |file|
      File.new(file, "w")
    end

    files_deleted = Fastlane::Helper::FilesystemHelper.delete_files("file_match_?", true)

    # verify function return value
    expect(files_deleted.sort).to eq files_match.sort

    # verify matching files were deleted
    files_match.each do |file|
      expect(File.exist?(file)).to be false
    end

    # verify non-matching files were not deleted
    files_no_match.each do |file|
      expect(File.exist?(file)).to be true
    end
  end

  it 'delete_files does not delete files when no files exist match given criteria' do
    files_no_match = ["file_no_match_1", "file_no_match_2"]

    # add files to temp directory
    files_no_match.each do |file|
      File.new(file, "w")
    end

    files_deleted = Fastlane::Helper::FilesystemHelper.delete_files("file_match_?", true)

    # verify function return value
    expect(files_deleted.empty?).to be true

    # verify non-matching files were not deleted
    files_no_match.each do |file|
      expect(File.exist?(file)).to be true
    end
  end

  it 'delete_files results are empty when no files exist' do
    files_deleted = Fastlane::Helper::FilesystemHelper.delete_files("file_match_?", true)

    # verify function return value
    expect(files_deleted.empty?).to be true
  end
end
