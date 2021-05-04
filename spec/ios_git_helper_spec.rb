require_relative './spec_helper'

describe Fastlane::Helper::Ios::GitHelper do
  describe '#get_from_env!' do
    let(:key) { 'a_key' }

    it 'shows an error when the value is not in the environment' do
      ENV[key] = nil

      expect(FastlaneCore::UI).to receive(:user_error!)
      described_class.get_from_env!(key: key)
    end

    it 'returns the value when in the environment' do
      ENV[key] = 'abc123'

      expect(FastlaneCore::UI).not_to receive(:user_error!)
      expect(described_class.get_from_env!(key: key)).to eq('abc123')
    end
  end
end
