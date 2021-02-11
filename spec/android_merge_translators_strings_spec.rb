require 'spec_helper.rb'
require 'tmpdir'

describe Fastlane::Actions::AndroidMergeTranslatorsStringsAction do
    before do
        @amtsTestUtils = AMTSTestUtils.new
        @amtsTestUtils.create_test_folder
    end

    it 'checks no merge' do
        amts_run_test('test-merge-android-nomerge.json')
    end

    it 'checks merge simple' do
        amts_run_test('test-merge-android-merge-simple.json')
    end

    it 'checks merge overwrite' do
        amts_run_test('test-merge-android-merge-overwrite.json')
    end

    it 'checks merge overwrite with double key in pending file' do
        amts_run_test('test-merge-android-merge-overwrite-double.json')
    end

    it 'checks merge overwrite with fuzzy strings' do
        amts_run_test('test-merge-android-merge-overwrite-fuzzy.json')
    end

    after do
        @amtsTestUtils.delete_test_folder
    end
end

def amts_run_test(script)
    test_script = @amtsTestUtils.get_test_from_file(script)
    @amtsTestUtils.create_test_data(test_script)
    Fastlane::Actions::AndroidMergeTranslatorsStringsAction.run({ strings_folder: @amtsTestUtils.test_folder_path })
    expect(@amtsTestUtils.read_result_data(test_script)).to eq(test_script['result']['content'])
end

class AMTSTestUtils
    attr_accessor :test_folder_path

    def initialize()
        @test_folder_path = File.join(Dir.tmpdir(), 'amts_tests')
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
        unless File.directory?(dir)
            FileUtils.mkdir_p(dir)
        end

        File.open(file_path, 'w') { |f| f.write(content) }
    end

    def read_result_data(test_script)
        file_path = File.join(@test_folder_path, test_script['result']['file'])
        return File.read(file_path)
    end
end
