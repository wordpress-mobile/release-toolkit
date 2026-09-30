# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::GenerateReleaseNotesFileAction do
  let(:header) { "*** Generated at code freeze.\n\n" }
  let(:history) { "25.6\n-----\n- [Internal] Keep this historical entry\n" }
  let(:original) { "#{header}25.7\n-----\n- Handwritten draft\n\n#{history}" }
  let(:markdown) do
    <<~MARKDOWN
      <!-- Release notes generated using configuration in .github/developer-release-notes.yml at trunk -->

      ## New PRs since [25.6](https://github.com/woocommerce/woocommerce-android/releases/tag/25.6)

      ### Changes
      * Fix checkout by @developer in https://github.com/woocommerce/woocommerce-android/pull/123
      * [*****] [WEAR] Update navigation by @bot[bot] in https://github.com/woocommerce/woocommerce-android/pull/124
      ## New Contributors
      * @developer made their first contribution in https://github.com/woocommerce/woocommerce-android/pull/123

      **Full Changelog**: https://github.com/woocommerce/woocommerce-android/compare/25.6...25.7
    MARKDOWN
  end
  let(:section) { "25.7\n-----\n#{markdown}\n" }
  let(:options) do
    {
      repository: 'woocommerce/woocommerce-android',
      tag_name: '25.7',
      target_commitish: 'published-sha',
      previous_tag: '25.6',
      configuration_file_path: '.github/developer-release-notes.yml',
      github_token: 'fake-token'
    }
  end

  before do
    allow(Fastlane::Actions::GetPrsBetweenTagsAction).to receive(:`).with('git rev-parse HEAD').and_return('published-sha')
    allow(Fastlane::Actions::GetPrsBetweenTagsAction).to receive(:run).and_return(markdown)
  end

  def generate(path, **overrides)
    run_described_fastlane_action(**options, version: '25.7', release_notes_file_path: path, **overrides)
  end

  it 'forwards the comparison options and requires API errors to fail' do
    expect(Fastlane::Actions::GetPrsBetweenTagsAction).to receive(:run) do |config|
      expect(config.values).to include(**options, fail_on_error: true)
      markdown
    end
    with_tmp_file(content: original) { |path| generate(path) }
  end

  it 'keeps the generated Markdown and replaces only the requested version' do
    with_tmp_file(content: original) do |path|
      expect(generate(path)).to eq(section)
      expect(File.read(path)).to eq(header + section + history)
      expect(Fastlane::Actions::ExtractReleaseNotesForVersionAction.run(version: '25.7', release_notes_file_path: path)).to eq(markdown.chomp(''))
    end
  end

  it 'inserts a missing version and is idempotent on subsequent runs' do
    with_tmp_file(content: header + history) do |path|
      2.times { generate(path) }
      expect(File.read(path)).to eq(header + section + history)
    end
  end

  it 'preserves a newer empty section when regenerating an older version' do
    with_tmp_file(content: "25.8\n-----\n\n#{original}") do |path|
      generate(path)
      expect(File.read(path)).to eq("25.8\n-----\n\n#{header}#{section}#{history}")
    end
  end

  it 'preserves CRLF line endings' do
    with_tmp_file(content: original.gsub("\n", "\r\n")) do |path|
      generate(path)
      expect(File.read(path)).to eq((header + section + history).gsub("\n", "\r\n"))
    end
  end

  ["\n", "\r\n"].each do |newline|
    it "normalizes CRLF Markdown to the file's #{newline.inspect} line endings" do
      allow(Fastlane::Actions::GetPrsBetweenTagsAction).to receive(:run).and_return(markdown.gsub("\n", "\r\n"))
      with_tmp_file(content: original.gsub("\n", newline)) do |path|
        generate(path)
        expect(File.read(path)).to eq((header + section + history).gsub("\n", newline))
      end
    end
  end

  it 'previews the generated section without writing' do
    with_tmp_file(content: original) do |path|
      expect(generate(path, dry_run: true)).to eq(section)
      expect(File.read(path)).to eq(original)
    end
  end

  it 'leaves the file untouched when GitHub fails' do
    allow(Fastlane::Actions::GetPrsBetweenTagsAction).to receive(:run).and_raise(Octokit::NotFound)
    with_tmp_file(content: original) do |path|
      expect { generate(path) }.to raise_error(Octokit::NotFound)
      expect(File.read(path)).to eq(original)
    end
  end

  it 'rejects an implicit comparison boundary' do
    with_tmp_file(content: original) do |path|
      expect { generate(path, previous_tag: nil) }.to raise_error(/explicit previous_tag/)
      expect(File.read(path)).to eq(original)
    end
  end

  it 'rejects an invalid version' do
    with_tmp_file(content: original) do |path|
      expect { generate(path, version: "25.7\nInjected") }.to raise_error(/numeric release version/)
      expect(File.read(path)).to eq(original)
    end
  end

  it 'accepts changes to the generated Markdown format without parsing PR entries' do
    notes = "## Changes\n- Fix checkout (#123) — developer\n\nThanks to our contributors!\n"
    allow(Fastlane::Actions::GetPrsBetweenTagsAction).to receive(:run).and_return(notes)
    with_tmp_file(content: original) do |path|
      generate(path)
      expect(File.read(path)).to eq("#{header}25.7\n-----\n#{notes}\n#{history}")
    end
  end

  it 'allows an empty release when all PRs have been excluded' do
    notes = "**Full Changelog**: https://github.com/woocommerce/woocommerce-android/compare/25.6...25.7\n"
    allow(Fastlane::Actions::GetPrsBetweenTagsAction).to receive(:run).and_return(notes)
    with_tmp_file(content: original) do |path|
      generate(path)
      expect(File.read(path)).to eq("#{header}25.7\n-----\n#{notes}\n#{history}")
    end
  end

  ["Unrecognized file format\n", "25.7\n-----\n\n25.7\n-----\n"].each do |invalid_contents|
    it "leaves an invalid file untouched: #{invalid_contents.inspect}" do
      with_tmp_file(content: invalid_contents) do |path|
        expect { generate(path) }.to raise_error(/No version headings|Duplicate release notes/)
        expect(File.read(path)).to eq(invalid_contents)
      end
    end
  end
end
