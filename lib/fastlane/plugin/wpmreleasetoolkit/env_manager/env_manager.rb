# frozen_string_literal: true

require 'dotenv'
# TODO: It would be nice to decouple this from Fastlane.
# To give a good UX in the current use case, however, it's best to access the Fastlane UI methods directly.
require 'fastlane'

# Manages loading of environment variables from a .env and accessing them in a user-friendly way.
class EnvManager
  attr_reader :env_path, :env_example_path

  class << self
    attr_writer :default_print_error_lambda
  end

  # Set up by loading the .env file with the given name.
  #
  # TODO: We could go one step and guess the name based on the repo URL.
  def initialize(
    env_file_name:,
    env_file_folder: File.join(Dir.home, '.a8c-apps'),
    example_env_file_path: 'fastlane/example.env',
    print_error_lambda: ->(message) { FastlaneCore::UI.user_error!(message) },
    print_warning_lambda: ->(message) { FastlaneCore::UI.important(message) }
  )
    @env_path = File.join(env_file_folder, env_file_name)
    @env_example_path = example_env_file_path
    @print_error_lambda = print_error_lambda
    @print_warning_lambda = print_warning_lambda

    unless File.exist?(@env_path) || running_on_ci?
      @print_warning_lambda.call("Warning: env file not found at #{@env_path}. Environment variables may not be loaded.")
    end

    Dotenv.load(@env_path)
  end

  # Use this instead of getting values from `ENV` directly. It will throw an error if the requested value is missing or empty.
  def get_required_env!(key)
    unless ENV.key?(key)
      message = "Environment variable '#{key}' is not set."

      error_message =
        if running_on_ci?
          message
        elsif File.exist?(@env_path)
          "#{message} Consider adding it to #{@env_path}."
        else
          env_file_dir = File.dirname(@env_path)
          env_file_name = File.basename(@env_path)

          <<~MSG
            #{env_file_name} not found in #{env_file_dir} while looking for env var #{key}.

            Please copy #{@env_example_path} to #{@env_path} and fill in the value for #{key}.

            mkdir -p #{env_file_dir} && cp #{@env_example_path} #{@env_path}
          MSG
        end

      @print_error_lambda.call(error_message)
      raise KeyError, error_message
    end

    value = ENV.fetch(key)

    if value.to_s.empty?
      empty_message = "Env var for key #{key} is set but empty. Please set a value for #{key}."
      @print_error_lambda.call(empty_message)
      raise ArgumentError, empty_message
    end

    value
  end

  # Use this to ensure all env vars a lane requires are set.
  #
  # The best place to call this is at the start of a lane, to fail early.
  def require_env_vars!(*keys)
    keys.flatten.each { |key| get_required_env!(key) }
  end

  # CI environment helpers — read common metadata from the CI provider.

  def build_number
    ENV.fetch('BUILDKITE_BUILD_NUMBER', '0')
  end

  def branch_name
    ENV.fetch('BUILDKITE_BRANCH', nil)
  end

  def commit_hash
    ENV.fetch('BUILDKITE_COMMIT', nil)
  end

  # Returns the PR number as an Integer, or nil if not running on a PR build.
  # Buildkite sets BUILDKITE_PULL_REQUEST to 'false' (not nil) when not on a PR.
  def pull_request_number
    pr_num = ENV.fetch('BUILDKITE_PULL_REQUEST', 'false')
    pr_num == 'false' ? nil : Integer(pr_num)
  end

  # Returns a human-readable label: "PR #123" for PR builds, or the branch name otherwise.
  def pr_number_or_branch_name
    pull_request_number&.then { |num| "PR ##{num}" } || branch_name
  end

  # Class-level convenience methods that delegate to a default instance.
  # This preserves the existing API: `EnvManager.set_up(...)` then `EnvManager.get_required_env!(...)`.

  def self.set_up(**args)
    if configured?
      default_print_error_lambda.call('EnvManager is already configured. Call `EnvManager.reset!` before calling `EnvManager.set_up(...)` again.')
      return @default
    end

    @default = new(**args)
  end

  def self.get_required_env!(key)
    default!.get_required_env!(key)
  end

  def self.require_env_vars!(*keys)
    default!.require_env_vars!(*keys)
  end

  # Clears the default instance, useful for test teardown.
  def self.reset!
    @default = nil
  end

  # Returns true if a default instance has been configured via `.set_up`.
  def self.configured?
    !@default.nil?
  end

  def self.default!
    return @default if configured?

    message = 'EnvManager is not configured. Call `EnvManager.set_up(...)` first.'
    default_print_error_lambda.call(message)
    raise message
  end

  def self.default_print_error_lambda
    @default&.instance_variable_get(:@print_error_lambda) || @default_print_error_lambda || ->(message) { FastlaneCore::UI.user_error!(message) }
  end

  private

  def running_on_ci?
    ENV['CI'] == 'true'
  end
end
