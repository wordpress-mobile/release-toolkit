# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Actions::IosGenerateStringsdictFromPoAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'stringsdict') }
  let(:ru_po) do
    <<~PO
      msgid ""
      msgstr ""
      "Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<12 || n%100>14) ? 1 : 2);\\n"

      msgctxt "%d items"
      msgid "%d item"
      msgid_plural "%d items"
      msgstr[0] "ru-one"
      msgstr[1] "ru-few"
      msgstr[2] "ru-many"
    PO
  end

  def fixture(name)
    File.join(test_data_dir, name)
  end

  it 'generates a localized .stringsdict and returns the (empty) missing list' do
    in_tmp_dir do |dir|
      po = File.join(dir, 'ru.po')
      File.write(po, ru_po)
      output = File.join(dir, 'ru.stringsdict')

      result = run_described_fastlane_action(
        po_path: po,
        template_path: fixture('simple.stringsdict'),
        locale: 'ru',
        output_path: output
      )

      expect(result).to eq([])
      data = Fastlane::Helper::Ios::StringsdictHelper.read(path: output)
      expect(data['%d items']['count'].slice('one', 'few', 'many', 'other')).to eq(
        'one' => 'ru-one', 'few' => 'ru-few', 'many' => 'ru-many', 'other' => 'ru-many'
      )
    end
  end

  it 'raises a user error when the template does not exist' do
    in_tmp_dir do |dir|
      po = File.join(dir, 'ru.po')
      File.write(po, ru_po)
      expect do
        run_described_fastlane_action(
          po_path: po,
          template_path: File.join(dir, 'missing.stringsdict'),
          locale: 'ru',
          output_path: File.join(dir, 'out.stringsdict')
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Stringsdict template not found/)
    end
  end

  it 'surfaces an unmappable locale (Welsh) as a clean user error' do
    in_tmp_dir do |dir|
      po = File.join(dir, 'cy.po')
      File.write(po, ru_po) # content irrelevant — the locale is rejected before any forms are read
      expect do
        run_described_fastlane_action(
          po_path: po,
          template_path: fixture('simple.stringsdict'),
          locale: 'cy',
          output_path: File.join(dir, 'out.stringsdict')
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Welsh/)
    end
  end
end
