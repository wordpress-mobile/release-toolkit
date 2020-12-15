require 'spec_helper.rb'
require 'fileutils'
require 'tmpdir'
require 'yaml'

describe Fastlane::Actions::IosLintLocalizationsAction do
  before do
    # Ensure `Action.sh` is not skipped during test – so that SwiftGen will be installed by our action as normal
    # See https://github.com/fastlane/fastlane/blob/master/fastlane_core/lib/fastlane_core/helper.rb#L68-L70
    ENV['FORCE_SH_DURING_TESTS'] = '1'
    # allow(FastlaneCore::Helper).to receive(:sh_enabled?).and_return(true) # Alternative solution 
  end

  context 'SwiftGen Installation Logic' do
    it 'only installs SwiftGen the first time, when it is not yet installed' do
      Dir.mktmpdir('a8c-lint-l10n-tests-swiftgen-install-') do |install_dir|
        Dir.mktmpdir('a8c-lint-l10n-tests-data-') do |empty_dataset|
          # Expect install dir to be empty before we start
          expect(Dir.entries(install_dir)).to eq(['.','..'])

          # First run: expect curl, unzip and cp_r to be called to install SwiftGen before it gets run
          expect_shell_command("curl", any_args, /\/.*swiftgen-6.4.0.zip/)
          expect_shell_command("unzip", any_args)
          expect(FileUtils).to receive(:cp_r)
          expect_shell_command("#{install_dir}/bin/swiftgen", "config", "run", "--config", anything)

          Fastlane::Actions::IosLintLocalizationsAction.run(
            install_path: install_dir,
            input_dir: empty_dataset,
            base_lang: 'en'
          )

          # Create a fake SwiftGen binstub to simulate SwiftGen has been installed at that point
          script = <<~SCRIPT
            #!/bin/sh
            echo "SwiftGen v6.4.0 (Fake binstub)"
          SCRIPT
          FileUtils.mkdir_p File.join(install_dir, 'bin')
          File.write(File.join(install_dir, 'bin/swiftgen'), script, { perm: 0766 })

          # Second run: ensure we only run SwiftGen directly, without a call to curl nor unzip beforehand
          expect_shell_command("#{install_dir}/bin/swiftgen", "config", "run", "--config", anything)

          Fastlane::Actions::IosLintLocalizationsAction.run(
            install_path: install_dir,
            input_dir: empty_dataset,
            base_lang: 'en'
          )
        end
      end
    end
  end

  context 'Linter' do
    before(:all) do
      @swiftgen_install_dir = Dir.mktmpdir('a8c-lint-l10n-tests-swiftgen-install-')
    end
    
    before(:each) do
      @test_data_dir = Dir.mktmpdir('a8c-lint-l10n-tests-data-')
    end

    it 'succeeds when there are no violations' do
      run_test('no-violations')
    end

    it 'detects inconsistent placeholder count' do
      run_test('wrong-placeholder-count')
    end

    it 'detects inconsistent placeholder types' do
      run_test('wrong-placeholder-types')
    end

    it 'detects invisible characters messing up placeholders' do
      run_test('tricky-chars')
    end

    it 'does not fail if a locale does not have any Localizable.strings' do
      run_test('no-strings')
    end

    after(:each) do
      FileUtils.remove_entry @test_data_dir
    end

    after(:all) do
      FileUtils.remove_entry @swiftgen_install_dir
    end
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

  # Act
  result = Fastlane::Actions::IosLintLocalizationsAction.run(
    install_path: @swiftgen_install_dir,
    input_dir: @test_data_dir,
    base_lang: 'en'
  )
  
  # Assert
  expect(result).to eq(yml["result"])
end

def expect_shell_command(*command, exitstatus: 0, output: "")
  mock_input = double(:input)
  mock_output = StringIO.new(output)
  mock_status = double(:status, exitstatus: exitstatus)
  mock_thread = double(:thread, value: mock_status)

  expect(Open3).to receive(:popen2e).with(*command).and_yield(mock_input, mock_output, mock_thread)
end
