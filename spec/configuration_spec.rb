require 'spec_helper.rb'

describe Fastlane::Configuration do
  describe 'initialization' do
    it 'creates an empty config' do
      expect(subject.project_name).to eq(Fastlane::Helper::FilesystemHelper.project_path.basename.to_s)
      expect(subject.branch).to eq('')
      expect(subject.pinned_hash).to eq('')
      expect(subject.files_to_copy).to eq([])
      expect(subject.file_dependencies).to eq([])
    end
  end

  describe 'file reading/writing' do
    let(:configure_path) { 'path/to/.configure' }

    let(:configure_json) do
      {
        project_name: 'MyProject',
        branch: 'a_branch',
        pinned_hash: 'a_hash',
        files_to_copy: [{ file: 'a_file_to_copy', destination: 'a_destination', encrypt: true }],
        file_dependencies: ['a_file_dependencies'],
      }
    end
    let(:configure_json_string) { JSON.pretty_generate(configure_json) }

    subject { Fastlane::Configuration.from_file(configure_path) }

    before(:each) do
      allow(File).to receive(:read).with(configure_path).and_return(configure_json_string)
      allow(File).to receive(:write).with(configure_path, configure_json_string)
    end

    it 'reads instantiates the configuration object from JSON' do
      expect(subject.branch).to eq(configure_json[:branch])
      expect(subject.pinned_hash).to eq(configure_json[:pinned_hash])
      expect(subject.file_dependencies).to eq(configure_json[:file_dependencies])

      expect(subject.files_to_copy.length).to eq(1)
      expect(subject.files_to_copy.first.file).to eq(configure_json[:files_to_copy][0][:file])
      expect(subject.files_to_copy.first.destination).to eq(configure_json[:files_to_copy][0][:destination])
      expect(subject.files_to_copy.first.encrypt).to eq(configure_json[:files_to_copy][0][:encrypt])
    end

    it 'write the configuration to disk as JSON' do
      expect(File).to receive(:write).with(configure_path, configure_json_string)

      subject.save_to_file(configure_path)
    end
  end

  describe '#add_file_to_copy' do
    it 'adds files to copy' do
      expect(subject.files_to_copy).to eq([])

      subject.add_file_to_copy('copy_file', 'to_here')

      expect(subject.files_to_copy.length).to eq(1)
      expect(subject.files_to_copy.first.file).to eq('copy_file')
      expect(subject.files_to_copy.first.destination).to eq('to_here')
    end
  end
end
