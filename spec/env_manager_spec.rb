# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::EnvManager do
  let(:errors) { [] }
  let(:print_error_lambda) do
    lambda do |message|
      errors << message
      raise message
    end
  end

  let(:warnings) { [] }
  let(:print_warning_lambda) { ->(message) { warnings << message } }

  # Capture and restore ENV state around each test
  around do |example|
    saved_env = ENV.to_h
    example.run
  ensure
    ENV.replace(saved_env)
    described_class.default_print_error_lambda = nil
  end

  describe '#initialize' do
    it 'sets env_path from folder and file name' do
      manager = described_class.new(
        env_file_name: 'my-app.env',
        env_file_folder: '/tmp/test-env',
        print_error_lambda: print_error_lambda
      )

      expect(manager.env_path).to eq('/tmp/test-env/my-app.env')
    end

    it 'defaults env_file_folder to ~/.a8c-apps' do
      manager = described_class.new(
        env_file_name: 'my-app.env',
        print_error_lambda: print_error_lambda
      )

      expect(manager.env_path).to eq(File.join(Dir.home, '.a8c-apps', 'my-app.env'))
    end

    it 'sets env_example_path' do
      manager = described_class.new(
        env_file_name: 'my-app.env',
        example_env_file_path: 'custom/example.env',
        print_error_lambda: print_error_lambda
      )

      expect(manager.env_example_path).to eq('custom/example.env')
    end

    it 'defaults env_example_path to fastlane/example.env' do
      manager = described_class.new(
        env_file_name: 'my-app.env',
        print_error_lambda: print_error_lambda
      )

      expect(manager.env_example_path).to eq('fastlane/example.env')
    end

    it 'loads values from the .env file without mutating ENV' do
      ENV.delete('TEST_INIT_VAR')

      with_tmp_file(named: 'test.env', content: "TEST_INIT_VAR=loaded\n") do |path|
        manager = described_class.new(
          env_file_name: File.basename(path),
          env_file_folder: File.dirname(path),
          print_error_lambda: print_error_lambda
        )

        expect(manager.get_required_env!('TEST_INIT_VAR')).to eq('loaded')
        expect(ENV.fetch('TEST_INIT_VAR', nil)).to be_nil
      end
    end

    it 'keeps multiple instances isolated from each other' do
      with_tmp_file(named: 'a.env', content: "SHARED_KEY=from_a\n") do |path_a|
        with_tmp_file(named: 'b.env', content: "SHARED_KEY=from_b\n") do |path_b|
          manager_a = described_class.new(
            env_file_name: File.basename(path_a),
            env_file_folder: File.dirname(path_a),
            print_error_lambda: print_error_lambda
          )
          manager_b = described_class.new(
            env_file_name: File.basename(path_b),
            env_file_folder: File.dirname(path_b),
            print_error_lambda: print_error_lambda
          )

          expect(manager_a.get_required_env!('SHARED_KEY')).to eq('from_a')
          expect(manager_b.get_required_env!('SHARED_KEY')).to eq('from_b')
        end
      end
    end

    it 'lets values in the process ENV take precedence over the .env file' do
      ENV['PRECEDENCE_KEY'] = 'from_env'

      with_tmp_file(named: 'p.env', content: "PRECEDENCE_KEY=from_file\n") do |path|
        manager = described_class.new(
          env_file_name: File.basename(path),
          env_file_folder: File.dirname(path),
          print_error_lambda: print_error_lambda
        )

        expect(manager.get_required_env!('PRECEDENCE_KEY')).to eq('from_env')
      end
    end

    it 'warns when the env file does not exist' do
      ENV.delete('CI')

      described_class.new(
        env_file_name: 'nonexistent.env',
        env_file_folder: '/tmp/no-such-dir',
        print_error_lambda: print_error_lambda,
        print_warning_lambda: print_warning_lambda
      )

      expect(warnings).to include(a_string_matching(/env file not found/))
    end

    it 'does not warn when the env file exists' do
      with_tmp_file(named: 'exists.env', content: '') do |path|
        described_class.new(
          env_file_name: File.basename(path),
          env_file_folder: File.dirname(path),
          print_error_lambda: print_error_lambda,
          print_warning_lambda: print_warning_lambda
        )

        expect(warnings).to be_empty
      end
    end

    it 'does not warn on CI even if the env file is missing' do
      ENV['CI'] = 'true'

      described_class.new(
        env_file_name: 'nonexistent.env',
        env_file_folder: '/tmp/no-such-dir',
        print_error_lambda: print_error_lambda,
        print_warning_lambda: print_warning_lambda
      )

      expect(warnings).to be_empty
    end

    # Guard against the common pitfall of a strict `CI == 'true'` check —
    # some providers set `CI=1` or similar truthy values.
    %w[true TRUE 1 yes on].each do |ci_value|
      it "treats CI=#{ci_value.inspect} as running on CI" do
        ENV['CI'] = ci_value

        described_class.new(
          env_file_name: 'nonexistent.env',
          env_file_folder: '/tmp/no-such-dir',
          print_error_lambda: print_error_lambda,
          print_warning_lambda: print_warning_lambda
        )

        expect(warnings).to be_empty
      end
    end

    %w[false FALSE 0].each do |ci_value|
      it "does not treat CI=#{ci_value.inspect} as running on CI" do
        ENV['CI'] = ci_value

        described_class.new(
          env_file_name: 'nonexistent.env',
          env_file_folder: '/tmp/no-such-dir',
          print_error_lambda: print_error_lambda,
          print_warning_lambda: print_warning_lambda
        )

        expect(warnings).not_to be_empty
      end
    end
  end

  describe '#get_required_env!' do
    subject(:manager) do
      described_class.new(
        env_file_name: 'test.env',
        env_file_folder: env_file_folder,
        print_error_lambda: print_error_lambda
      )
    end

    let(:env_file_folder) { '/tmp/nonexistent-env-folder' }

    it 'returns the value when the env var is set' do
      ENV['TEST_KEY'] = 'test_value'

      expect(manager.get_required_env!('TEST_KEY')).to eq('test_value')
    end

    context 'when the env var is missing' do
      before { ENV.delete('MISSING_KEY') }

      it 'prints a CI-specific error when running on CI' do
        ENV['CI'] = 'true'

        expect { manager.get_required_env!('MISSING_KEY') }
          .to raise_error("Environment variable 'MISSING_KEY' is not set.")
      end

      it 'suggests adding the var to the env file when the file exists' do
        ENV.delete('CI')

        in_tmp_dir do |tmpdir|
          env_path = File.join(tmpdir, 'test.env')
          File.write(env_path, '')

          local_manager = described_class.new(
            env_file_name: 'test.env',
            env_file_folder: tmpdir,
            print_error_lambda: print_error_lambda
          )

          expect { local_manager.get_required_env!('MISSING_KEY') }
            .to raise_error("Environment variable 'MISSING_KEY' is not set. Consider adding it to #{env_path}.")
        end
      end

      it 'prints setup instructions when the env file does not exist' do
        ENV.delete('CI')

        expect { manager.get_required_env!('MISSING_KEY') }
          .to raise_error(%r{test\.env not found in /tmp/nonexistent-env-folder})
      end

      it 'escapes paths with spaces in the shell command' do
        ENV.delete('CI')

        spaced_manager = described_class.new(
          env_file_name: 'test.env',
          env_file_folder: '/tmp/path with spaces',
          example_env_file_path: 'lane/example file.env',
          print_error_lambda: print_error_lambda
        )

        expect { spaced_manager.get_required_env!('MISSING_KEY') }
          .to raise_error(%r{mkdir -p /tmp/path\\ with\\ spaces && cp lane/example\\ file\.env /tmp/path\\ with\\ spaces/test\.env})
      end

      it 'raises KeyError even when the error lambda does not raise' do
        ENV['CI'] = 'true'
        non_raising_errors = []

        non_raising_manager = described_class.new(
          env_file_name: 'test.env',
          env_file_folder: '/tmp',
          print_error_lambda: ->(message) { non_raising_errors << message }
        )

        expect { non_raising_manager.get_required_env!('MISSING_KEY') }
          .to raise_error(KeyError, /MISSING_KEY/)
        expect(non_raising_errors).to include(a_string_matching(/not set/))
      end
    end

    it 'prints an error when the env var is set but empty' do
      ENV['EMPTY_KEY'] = ''

      expect { manager.get_required_env!('EMPTY_KEY') }
        .to raise_error(/is set but empty/)
    end

    it 'raises ArgumentError for empty values even when the error lambda does not raise' do
      ENV['EMPTY_KEY'] = ''
      non_raising_errors = []

      non_raising_manager = described_class.new(
        env_file_name: 'test.env',
        env_file_folder: '/tmp',
        print_error_lambda: ->(message) { non_raising_errors << message }
      )

      expect { non_raising_manager.get_required_env!('EMPTY_KEY') }
        .to raise_error(ArgumentError, /is set but empty/)
      expect(non_raising_errors).to include(a_string_matching(/is set but empty/))
    end
  end

  describe '#require_env_vars!' do
    subject(:manager) do
      described_class.new(
        env_file_name: 'test.env',
        env_file_folder: '/tmp',
        print_error_lambda: print_error_lambda
      )
    end

    it 'validates each key' do
      ENV['KEY_A'] = 'a'
      ENV['KEY_B'] = 'b'

      result_a = manager.get_required_env!('KEY_A')
      result_b = manager.get_required_env!('KEY_B')

      manager.require_env_vars!('KEY_A', 'KEY_B')

      expect(result_a).to eq('a')
      expect(result_b).to eq('b')
    end

    it 'accepts an array of keys' do
      ENV['KEY_A'] = 'a'
      ENV['KEY_B'] = 'b'

      manager.require_env_vars!(%w[KEY_A KEY_B])

      expect(manager.get_required_env!('KEY_A')).to eq('a')
      expect(manager.get_required_env!('KEY_B')).to eq('b')
    end

    it 'raises on the first missing key' do
      ENV['KEY_A'] = 'a'
      ENV.delete('KEY_B')

      expect { manager.require_env_vars!('KEY_A', 'KEY_B') }
        .to raise_error(/KEY_B/)
    end
  end

  describe 'CI environment helpers' do
    subject(:manager) do
      described_class.new(
        env_file_name: 'test.env',
        env_file_folder: '/tmp',
        print_error_lambda: print_error_lambda
      )
    end

    describe '#build_number' do
      it 'returns the Buildkite build number' do
        ENV['BUILDKITE_BUILD_NUMBER'] = '42'

        expect(manager.build_number).to eq('42')
      end

      it 'defaults to 0 when not set' do
        ENV.delete('BUILDKITE_BUILD_NUMBER')

        expect(manager.build_number).to eq('0')
      end
    end

    describe '#branch_name' do
      it 'returns the Buildkite branch' do
        ENV['BUILDKITE_BRANCH'] = 'feature/cool'

        expect(manager.branch_name).to eq('feature/cool')
      end

      it 'returns nil when not set' do
        ENV.delete('BUILDKITE_BRANCH')

        expect(manager.branch_name).to be_nil
      end
    end

    describe '#commit_hash' do
      it 'returns the Buildkite commit' do
        ENV['BUILDKITE_COMMIT'] = 'abc123'

        expect(manager.commit_hash).to eq('abc123')
      end

      it 'returns nil when not set' do
        ENV.delete('BUILDKITE_COMMIT')

        expect(manager.commit_hash).to be_nil
      end
    end

    describe '#pull_request_number' do
      it 'returns the PR number as an integer' do
        ENV['BUILDKITE_PULL_REQUEST'] = '99'

        expect(manager.pull_request_number).to eq(99)
      end

      it 'returns nil when set to false' do
        ENV['BUILDKITE_PULL_REQUEST'] = 'false'

        expect(manager.pull_request_number).to be_nil
      end

      it 'returns nil when not set' do
        ENV.delete('BUILDKITE_PULL_REQUEST')

        expect(manager.pull_request_number).to be_nil
      end
    end

    describe '#pr_number_or_branch_name' do
      it 'returns PR label when on a PR build' do
        ENV['BUILDKITE_PULL_REQUEST'] = '42'
        ENV['BUILDKITE_BRANCH'] = 'feature/x'

        expect(manager.pr_number_or_branch_name).to eq('PR #42')
      end

      it 'falls back to branch name when not on a PR' do
        ENV['BUILDKITE_PULL_REQUEST'] = 'false'
        ENV['BUILDKITE_BRANCH'] = 'trunk'

        expect(manager.pr_number_or_branch_name).to eq('trunk')
      end

      it 'returns nil when neither PR nor branch is set' do
        ENV.delete('BUILDKITE_PULL_REQUEST')
        ENV.delete('BUILDKITE_BRANCH')

        expect(manager.pr_number_or_branch_name).to be_nil
      end
    end
  end

  describe 'class-level convenience methods' do
    before do
      described_class.reset!
      described_class.set_up(
        env_file_name: 'test.env',
        env_file_folder: '/tmp',
        print_error_lambda: print_error_lambda
      )
    end

    after { described_class.reset! }

    describe '.set_up' do
      it 'raises a clear error when called twice without reset' do
        expect do
          described_class.set_up(
            env_file_name: 'other.env',
            env_file_folder: '/tmp',
            print_error_lambda: print_error_lambda
          )
        end.to raise_error('EnvManager is already configured. Call `EnvManager.reset!` before calling `EnvManager.set_up(...)` again.')
      end

      it 'does not overwrite the default instance when the error lambda does not raise' do
        # Set up with a non-raising error lambda so we can verify the guard behavior
        described_class.reset!
        non_raising_errors = []
        non_raising_lambda = ->(message) { non_raising_errors << message }

        described_class.set_up(
          env_file_name: 'test.env',
          env_file_folder: '/tmp',
          print_error_lambda: non_raising_lambda
        )
        original_default = described_class.send(:instance_variable_get, :@default)

        # Second call should not overwrite the original
        described_class.set_up(
          env_file_name: 'other.env',
          env_file_folder: '/tmp',
          print_error_lambda: non_raising_lambda
        )

        expect(described_class.send(:instance_variable_get, :@default)).to equal(original_default)
        expect(non_raising_errors).to include(a_string_matching(/already configured/))
      end
    end

    describe '.get_required_env!' do
      it 'delegates to the default instance' do
        ENV['CLASS_KEY'] = 'class_value'

        expect(described_class.get_required_env!('CLASS_KEY')).to eq('class_value')
      end

      it 'raises a clear error when called before set_up' do
        described_class.reset!
        described_class.default_print_error_lambda = print_error_lambda

        expect { described_class.get_required_env!('CLASS_KEY') }
          .to raise_error('EnvManager is not configured. Call `EnvManager.set_up(...)` first.')
      end

      it 'raises even when the error lambda does not raise' do
        described_class.reset!
        described_class.default_print_error_lambda = ->(message) { errors << message }

        expect { described_class.get_required_env!('CLASS_KEY') }
          .to raise_error(RuntimeError, 'EnvManager is not configured. Call `EnvManager.set_up(...)` first.')
        expect(errors).to include(a_string_matching(/not configured/))
      end
    end

    describe '.require_env_vars!' do
      it 'delegates to the default instance' do
        ENV['CK1'] = 'v1'
        ENV['CK2'] = 'v2'

        expect { described_class.require_env_vars!('CK1', 'CK2') }.not_to raise_error
      end

      it 'raises a clear error when called before set_up' do
        described_class.reset!
        described_class.default_print_error_lambda = print_error_lambda

        expect { described_class.require_env_vars!('CK1', 'CK2') }
          .to raise_error('EnvManager is not configured. Call `EnvManager.set_up(...)` first.')
      end
    end

    describe '.reset!' do
      it 'clears the default instance' do
        expect(described_class).to be_configured

        described_class.reset!

        expect(described_class).not_to be_configured
      end
    end

    describe '.configured?' do
      it 'returns false before set_up' do
        described_class.reset!

        expect(described_class).not_to be_configured
      end

      it 'returns true after set_up' do
        expect(described_class).to be_configured
      end
    end
  end
end
