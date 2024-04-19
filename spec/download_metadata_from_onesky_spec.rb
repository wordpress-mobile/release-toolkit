require 'spec_helper'

describe Fastlane::Actions::DownloadMetadataFromOneskyAction do
  describe 'derives a build code from an AppVersion object' do
    let(:api_key) { 'dummy-api-key' }
    let(:api_secret) { 'dummy-api-secret' }
    let(:project_id) { 123_456 }
    let(:export_content) { File.read(File.join(File.dirname(__FILE__), 'test-data', 'onesky-metadata.json')) }

    before do
      client = instance_double(Onesky::Client)
      allow(Onesky::Client).to receive(:new).and_return(client)
      project = instance_double(Onesky::Project)
      allow(client).to receive(:project).and_return(project)
      allow(project).to receive(:export_multilingual).with(
        source_file_name: 'store-metadata.xml',
        file_format: 'I18NEXT_MULTILINGUAL_JSON'
      ).and_return(export_content)
    end

    def run_test(metadata_files:, expected_content:)
      in_tmp_dir do |tmp_dir|
        run_described_fastlane_action(
          onesky_api_key: api_key,
          onesky_api_secret: api_secret,
          onesky_project_id: project_id,
          source_file_name: 'store-metadata.xml',
          metadata_files: metadata_files,
          locales: Fastlane::LocalesMap.default.to_h(:onesky, :app_store)
        )

        expected_content.each do |path, content|
          if content.nil?
            expect(File).not_to exist(File.join(tmp_dir, 'metadata', path.to_s))
          else
            expect(File).to exist(File.join(tmp_dir, 'metadata', path.to_s))
            expect(File.read(File.join(tmp_dir, 'metadata', path.to_s))).to eq(content)
          end
        end
      end
    end

    it 'works' do
      metadata_files = {
        'name.txt': { key: 'app_title_2021', max: 30 }
        # 'subtitle.txt': { key: 'app_subtitle_10_2021', max: 30 },
        # 'promotional_text.txt': { key: nil, max: 170 },
        # 'keywords.txt': { key: 'app_keywords_5_2021', max: 100 },
        # 'description.txt': {
        #   key: 'app_description_8_2023',
        #   max: 4000,
        #   alt: 'app_description_8_2023_short',
        #   # The copy we actually use for English in ASC is different from the (shorter) English copy we provide translators in OneSky
        #   skip_enUS: true # So we don't want to update en-US/description.txt with the OneSky English copy.
        # },
        # 'release_notes.txt': { key: 'bugfix_Explore_4.1', max: 4000 }
      }

      run_test(
        metadata_files: metadata_files,
        expected_content: {
          'en-US/name.txt': "Tumblr: Home of Fandom\n",
          'de-DE/name.txt': nil,
          'fr-FR/name.txt': nil,
          'pt-BR/name.txt': "Tumblr: o lar dos fandoms.\n"
        }
      )
    end
  end
end
