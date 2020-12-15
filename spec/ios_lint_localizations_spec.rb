require 'spec_helper.rb'
require 'fileutils'
require 'tmpdir'
require 'yaml'

describe Fastlane::Actions::IosLintLocalizationsAction do
    before do
        @test_sandbox = File.join(Dir.tmpdir, 'a8c-lint-l10n-tests')
        FileUtils.mkdir_p(@test_sandbox)
        @swiftgen_install_dir = File.join(@test_sandbox, 'swiftgen-install-dir')
        @test_data_dir = File.join(@test_sandbox, 'test_data')
    end

    it 'succeeds when there are no violations' do
        run_test('no-violations')
    end

    it 'detects inconsistent placeholder count' do
        run_test('wrong-placeholder-count')
    end

    # it 'detects inconsistent placeholder types' do
    #     run_test('wrong-placeholder-types')
    # end

    # it 'detects invisible characters messing up placeholders' do
    #     run_test('tricky-placeholder')
    # end

    # it 'does not fail if a locale does not have any Localizable.strings' do
    #     run_test('no-strings')
    # end

    after do
        # FileUtils.remove_entry @test_sandbox
    end
end

def run_test(data_file)
    # Arrange: Prepare test files

    test_file = File.join(File.dirname(__FILE__), 'test-data', 'translations', "test-lint-ios-#{data_file}.yaml")
    yml = YAML.load_file(test_file)

    files = yml['test_data']
    FileUtils.mkdir_p(@test_data_dir)
    files.each do |lang, content|
        lproj = File.join(@test_data_dir, "#{lang}.lproj")
        FileUtils.mkdir_p(lproj)
        File.write(File.join(lproj, 'Localizable.strings'), content) unless content.nil?
    end
    # Dir.glob("#{@test_data_dir}/**/*.strings").each { |f| puts "-- #{f} --"; puts File.read(f) } # for DEBUG

    # Ensure `Action.sh` is not skipped during test – so that SwiftGen will be installed by our action as normal
    # See https://github.com/fastlane/fastlane/blob/master/fastlane_core/lib/fastlane_core/helper.rb#L68-L70
    ENV['FORCE_SH_DURING_TESTS'] = '1'
    # allow(FastlaneCore::Helper).to receive(:sh_enabled?).and_return(true) # Alternative solution

    # Act
    result = Fastlane::Actions::IosLintLocalizationsAction.run(
        install_path: @swiftgen_install_dir,
        input_dir: @test_data_dir,
        base_lang: 'en'
    )
    
    # Assert
    expect(result).to eq(yml["result"])
end
