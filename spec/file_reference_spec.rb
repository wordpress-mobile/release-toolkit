require 'spec_helper.rb'

RSpec.shared_examples 'shared examples' do
  describe '#destination_contents' do
    it 'gets the contents from the destination path, when it exists' do
      allow(File).to receive(:file?).with(subject.destination_file_path).and_return(true)
      allow(File).to receive(:read).with(subject.destination_file_path).and_return('destination contents')
      expect(subject.destination_contents).to eq('destination contents')
    end

    it 'gives nil if the file does not exist' do
      allow(File).to receive(:file?).with(subject.destination_file_path).and_return(false)
      expect(subject.destination_contents).to eq(nil)
    end
  end

  describe '#needs_apply?' do
    it 'needs apply when source and destination differ' do
      allow(subject).to receive(:source_contents).and_return('source contents')
      allow(subject).to receive(:destination_contents).and_return('destination contents')
      expect(subject.needs_apply?).to eq(true)
    end

    it 'does not need apply when source and destination are equal' do
      allow(subject).to receive(:source_contents).and_return('source contents')
      allow(subject).to receive(:destination_contents).and_return('source contents')
      expect(subject.needs_apply?).to eq(false)
    end
  end

  describe '#apply' do
    it 'copies the source to the destination' do
      allow(FileUtils).to receive(:mkdir_p)
      allow(subject).to receive(:source_contents).and_return('source contents')
      expect(File).to receive(:write).with(subject.destination_file_path, 'source contents')
      subject.apply
    end
  end
end

describe Fastlane::Configuration::FileReference do
  describe 'initialization' do
    it 'creates an empty file reference' do
      expect(subject.file).to eq("")
      expect(subject.destination).to eq("")
      expect(subject.encrypt).to eq(false)
    end
  end

  describe 'without encryption' do
    let(:subject) { Fastlane::Configuration::FileReference.new(file: 'path/to/file', destination: 'destination', encrypt: false) }

    include_examples 'shared examples'

    describe '#source_contents' do
      it 'gets the contents from the secrets repo' do
        set_circle_env(false) do
          allow(File).to receive(:read).with(subject.secrets_repository_file_path).and_return('source contents')
          expect(subject.source_contents).to eq('source contents')
        end
      end
    end

    describe '#source_contents on ci' do
      it 'gets the contents from the secrets repo' do
        set_circle_env(true) do
          allow(File).to receive(:read).with(subject.secrets_repository_file_path).and_return('source contents')
          expect(subject.source_contents).to eq(nil)
        end
      end
    end

    describe '#update' do
      it 'does nothing' do
        expect(File).not_to receive(:write)
        subject.update
      end
    end
  end

  describe 'with encryption' do
    let(:subject) { Fastlane::Configuration::FileReference.new(file: 'path/to/file', destination: 'destination', encrypt: true) }

    before(:each) do
      allow(Fastlane::Helper::ConfigureHelper).to receive(:encryption_key).and_return('key')
    end

    include_examples 'shared examples'

    describe '#source_contents' do
      it 'gives the descrypted contents, when it exists' do
        allow(File).to receive(:file?).with(subject.encrypted_file_path).and_return(true)
        allow(File).to receive(:read).with(subject.encrypted_file_path).and_return('encrypted contents')
        expect(Fastlane::Helper::EncryptionHelper).to receive(:decrypt).with('encrypted contents', 'key').and_return('decrypted contents')
        expect(subject.source_contents).to eq('decrypted contents')
      end
  
      it 'gives nil if the encrypted does not exist' do
        allow(File).to receive(:file?).with(subject.encrypted_file_path).and_return(false)
        expect(subject.source_contents).to eq(nil)
      end
    end

    describe '#update' do
      it 'updates the encrypted file' do
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:read).with(subject.secrets_repository_file_path).and_return('source contents')
        expect(Fastlane::Helper::EncryptionHelper).to receive(:encrypt).with('source contents', 'key').and_return('encrypted contents')
        expect(File).to receive(:write).with(subject.encrypted_file_path, 'encrypted contents')
        subject.update
      end
    end
  end
end
