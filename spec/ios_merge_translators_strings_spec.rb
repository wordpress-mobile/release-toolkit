require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::IosMergeTranslatorsStringsAction do
  before do
    @imtsTestUtils = IMTSTestUtils.new
    @imtsTestUtils.create_test_folder
  end

  it 'checks no merge' do
    imts_run_test('test-merge-ios-nomerge.json')
  end

  it 'checks merge simple' do
    imts_run_test('test-merge-ios-merge-simple.json')
  end

  it 'checks merge overwrite' do
    imts_run_test('test-merge-ios-merge-overwrite.json')
  end

  it 'checks merge overwrite with double key in pending file' do
    imts_run_test('test-merge-ios-merge-overwrite-double.json')
  end

  it 'checks merge overwrite with fuzzy strings' do
    imts_run_test('test-merge-ios-merge-overwrite-fuzzy.json')
  end

  after do
    @imtsTestUtils.delete_test_folder
  end
end

def imts_run_test(script)
  test_script = @imtsTestUtils.get_test_from_file(script)
  @imtsTestUtils.create_test_data(test_script)
  run_described_fastlane_action(strings_folder: @imtsTestUtils.test_folder_path)
  expect(@imtsTestUtils.read_result_data(test_script)).to eq(test_script['result']['content'])
end

class IMTSTestUtils
  attr_accessor :test_folder_path

  def initialize
    @test_folder_path = File.join(Dir.tmpdir(), 'imts_tests')
  end

  def create_test_folder
    FileUtils.mkdir_p(@test_folder_path)
  end

  def delete_test_folder
    FileUtils.rm_rf(@test_folder_path)
  end

  def get_test_from_file(filename)
    filename = self.test_data_path_for("translations/#{filename}")
    return JSON.parse(open(filename).read)
  end

  def test_data_path_for(filename)
    File.expand_path(File.join(File.dirname(__FILE__), 'test-data', filename))
  end

  def create_test_data(test_script)
    test_script['test_data'].each do |test_file|
      self.generate_test_file(test_file['file'], test_file['content'])
    end
  end

  def generate_test_file(filename, content)
    file_path = File.join(@test_folder_path, filename)

    dir = File.dirname(file_path)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    File.open(file_path, 'w') { |f| f.write(content) }
  end

  def read_result_data(test_script)
    file_path = File.join(@test_folder_path, test_script['result']['file'])
    return File.read(file_path)
  end
end
