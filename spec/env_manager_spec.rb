# frozen_string_literal: true

require 'spec_helper'

describe EnvManager do
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

    it 'loads the .env file via Dotenv' do
      with_tmp_file(named: 'test.env', content: "TEST_INIT_VAR=loaded\n") do |path|
        described_class.new(
          env_file_name: File.basename(path),
          env_file_folder: File.dirname(path),
          print_error_lambda: print_error_lambda
        )

        expect(ENV.fetch('TEST_INIT_VAR', nil)).to eq('loaded')
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
    end

    it 'prints an error when the env var is set but empty' do
      ENV['EMPTY_KEY'] = ''

      expect { manager.get_required_env!('EMPTY_KEY') }
        .to raise_error(/is set but empty/)
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
    end

    describe '.require_env_vars!' do
      it 'delegates to the default instance' do
        ENV['CK1'] = 'v1'
        ENV['CK2'] = 'v2'

        expect(described_class.get_required_env!('CK1')).to eq('v1')
        expect(described_class.get_required_env!('CK2')).to eq('v2')
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
