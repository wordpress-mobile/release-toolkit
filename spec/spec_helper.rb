$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'simplecov'
require 'codecov'
require 'webmock/rspec'

# SimpleCov.minimum_coverage 95
SimpleCov.start

code_coverage_token = ENV['CODECOV_TOKEN'] || false

# If the environment variable is present, format for Codecov
SimpleCov.formatter = SimpleCov::Formatter::Codecov if code_coverage_token

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/wpmreleasetoolkit' # import the actual plugin

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)

RSpec.configure do |config|
  config.filter_run_when_matching :focus
end

# Allows Action.sh to be executed even when running in a test environment (where Fastlane's code disables it by default)
#
def allow_fastlane_action_sh
  # See https://github.com/fastlane/fastlane/blob/e6bd288f17038a39cd1bfc1b70373cab1fa1e173/fastlane/lib/fastlane/helper/sh_helper.rb#L45-L85
  allow(FastlaneCore::Helper).to receive(:sh_enabled?).and_return(true)
end

# Allow us to do `.with` matching against a `File` instance to a particular path in RSpec expectations
# (Because `File.open(path)` returns a different instance of `File` for the same path on each call)
RSpec::Matchers.define :file_instance_of do |path|
  match { |actual| actual.is_a?(File) && actual.path == path }
end

# Allows to assert if an `Action.sh` command has been triggered by the action under test.
# Requires `allow_fastlane_action_sh` to have been called so that `Action.sh` actually calls `Open3.popen2e`
#
# @param [String...] *command List of the command and its parameters to run
# @param [Int] exitstatus The exit status to expect. Defaults to 0.
# @param [String] output The output string to expect as a result of running the command. Defaults to "".
# @return [MessageExpectation] self, to support further chaining.
#
def expect_shell_command(*command, exitstatus: 0, output: '')
  mock_input = double(:input)
  mock_output = StringIO.new(output)
  mock_status = double(:status, exitstatus: exitstatus)
  mock_thread = double(:thread, value: mock_status)

  expect(Open3).to receive(:popen2e).with(*command).and_yield(mock_input, mock_output, mock_thread)
end

# If the `described_class` of a spec is a `Fastlane::Action` subclass, it runs it with the given parameters.
#
def run_described_fastlane_action(parameters)
  raise "Only call `#{__callee__}` from a spec describing a `Fastlane::Action` subclass." unless Fastlane::Actions.is_class_action?(described_class)

  # Avoid logging messages about deprecated actions while running tests on them
  allow(Fastlane::Actions).to receive(:is_deprecated?).and_return(false)
  lane = <<~LANE
    lane :test do
      #{described_class.action_name}(
        #{parameters.inspect}
      )
    end
  LANE
  Fastlane::FastFile.new.parse(lane).runner.execute(:test)
end

# Executes the given block within an ad hoc temporary directory.
def in_tmp_dir
  Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmpdir|
    Dir.chdir(tmpdir) do
      yield tmpdir
    end
  end
end

# Executes the given block with a temporary file with the given `file_name`
def with_tmp_file(named: nil, content: '')
  in_tmp_dir do |tmp_dir|
    file_name = named || ('a'..'z').to_a.sample(8).join # 8-character random file name if nil
    file_path = File.join(tmp_dir, file_name)

    File.write(file_path, content)
    yield file_path
  ensure
    File.delete(file_path)
  end
end

# File Path Helpers
EMPTY_FIREBASE_TEST_LOG_PATH = File.join(__dir__, 'test-data', 'empty.json')
PASSED_FIREBASE_TEST_LOG_PATH = File.join(__dir__, 'test-data', 'firebase', 'firebase-test-lab-run-passed.log')
FAILED_FIREBASE_TEST_LOG_PATH = File.join(__dir__, 'test-data', 'firebase', 'firebase-test-lab-run-failure.log')
