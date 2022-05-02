require 'spec_helper'

EMPTY_FIREBASE_TEST_LOG_PATH = File.join(__dir__, 'test-data', 'empty.json')
FAILED_FIREBASE_TEST_LOG_PATH = File.join(__dir__, 'test-data', 'firebase', 'failed-firebase-test-lab-run.log')
INVALID_TEST_LOG_PATH = 'foo'.freeze

describe Fastlane::FirebaseTestLabLogFile do
  let(:empty_test_log) { described_class.new(path: EMPTY_FIREBASE_TEST_LOG_PATH) }
  let(:failed_test_log) { described_class.new(path: FAILED_FIREBASE_TEST_LOG_PATH) }

  describe 'initialize' do
    it 'raises for an invalid file path' do
      expect { described_class.new(path: INVALID_TEST_LOG_PATH) }.to raise_exception 'No log file found at path foo'
    end
  end

  describe 'more_details_url' do
    it 'returns the "more details url"' do
      expect(failed_test_log.more_details_url).to eq 'https://console.firebase.google.com/project/redacted/testlab/histories/bh.edfd947f2636efe3/matrices/4770383643393920434'
    end

    it 'returns nil if not present' do
      expect(empty_test_log.more_details_url).to be_nil
    end
  end

  describe 'raw_results_paths' do
    it 'returns the bucket name for the raw results' do
      expect(failed_test_log.raw_results_paths[:bucket]).to eq 'test-lab-wjdmcn8vd90jx-wfb9uburfx80m'
    end

    it 'returns the prefix for the raw results' do
      expect(failed_test_log.raw_results_paths[:prefix]).to eq '2022-04-05_18:37:28.338803_oTen'
    end

    it 'returns nil if not present' do
      expect(empty_test_log.raw_results_paths).to be_nil
    end
  end
end
