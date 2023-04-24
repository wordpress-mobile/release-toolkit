require 'spec_helper'

describe Fastlane::Actions::IosRegisterCiMachineAction do
  let(:other_action) { instance_double('other_action') }

  before do
    allow(Fastlane::OtherAction).to receive(:new).and_return(other_action)
    allow(other_action).to receive(:register_device)
  end

  describe '#ios_register_ci_machine' do
    it 'do nothing if not running on CI' do
      allow(other_action).to receive(:is_ci).and_return(false)
      expect(other_action).not_to receive(:register_device)
      run_described_fastlane_action(api_key_path: '', team_id: '')
    end

    it 'registers the device with the proper parameters' do
      allow(other_action).to receive(:is_ci).and_return(true)
      expect(other_action).to receive(:register_device)
        .with(hash_including(api_key_path: 'api-key.json', team_id: 'ABC'))
      run_described_fastlane_action(
        api_key_path: 'api-key.json',
        team_id: 'ABC'
      )
    end
  end
end
