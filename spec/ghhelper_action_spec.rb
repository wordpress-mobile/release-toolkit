describe Fastlane::Actions::GhhelperAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The ghhelper plugin is working!")

      Fastlane::Actions::GhhelperAction.run(nil)
    end
  end
end
