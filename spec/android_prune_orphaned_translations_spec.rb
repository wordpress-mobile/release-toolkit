# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

describe Fastlane::Actions::AndroidPruneOrphanedTranslationsAction do
  # Writes `content` to `path`, creating intermediate directories.
  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  # A default `values/strings.xml` declaring `hello`, `bye`, an array and a plural.
  let(:default_strings) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <resources>
          <string name="hello">Hello</string>
          <string name="bye">Bye</string>
          <string-array name="planets">
              <item>Earth</item>
          </string-array>
          <plurals name="items">
              <item quantity="one">%d item</item>
              <item quantity="other">%d items</item>
          </plurals>
      </resources>
    XML
  end

  it 'removes only the entries whose key is not in the default strings, keeping the rest intact' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      write_file(File.join(res_dir, 'values', 'strings.xml'), default_strings)
      fr_file = File.join(res_dir, 'values-fr', 'strings.xml')
      write_file(fr_file, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="hello">Bonjour</string>
            <string name="orphan_string">Orphelin</string>
            <string name="bye">Au revoir</string>
            <plurals name="orphan_plural">
                <item quantity="one">%d truc</item>
                <item quantity="other">%d trucs</item>
            </plurals>
        </resources>
      XML

      pruned = run_described_fastlane_action(res_dir: res_dir)

      expect(pruned).to eq(2)
      content = File.read(fr_file)
      expect(content).to include('name="hello"', 'name="bye"')
      expect(content).not_to include('orphan_string', 'orphan_plural')
      # No blank line left behind where the orphaned <string> was removed.
      expect(content).not_to match(/\n[[:space:]]*\n[[:space:]]*<string name="bye"/)
    end
  end

  it 'leaves non-locale qualifier directories (e.g. values-night) untouched' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      write_file(File.join(res_dir, 'values', 'strings.xml'), default_strings)
      # A non-locale qualifier dir with a key absent from the default must NOT be pruned.
      night_file = File.join(res_dir, 'values-night', 'strings.xml')
      night_content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="night_only">Night</string>
        </resources>
      XML
      write_file(night_file, night_content)
      # A real locale dir with an orphan, to confirm pruning still happens there.
      fr_file = File.join(res_dir, 'values-fr', 'strings.xml')
      write_file(fr_file, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="hello">Bonjour</string>
            <string name="orphan_string">Orphelin</string>
        </resources>
      XML

      pruned = run_described_fastlane_action(res_dir: res_dir)

      expect(pruned).to eq(1)
      expect(File.read(night_file)).to eq(night_content)
      expect(File.read(fr_file)).not_to include('orphan_string')
    end
  end

  it 'leaves car UI mode qualifier directories untouched' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      write_file(File.join(res_dir, 'values', 'strings.xml'), default_strings)
      car_file = File.join(res_dir, 'values-car', 'strings.xml')
      car_content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="car_only">Car</string>
        </resources>
      XML
      write_file(car_file, car_content)

      pruned = run_described_fastlane_action(res_dir: res_dir)

      expect(pruned).to eq(0)
      expect(File.read(car_file)).to eq(car_content)
    end
  end

  # `kmr` (Northern Kurdish) is a real 3-letter legacy locale used by e.g. WordPress-Android, so it must still be
  # pruned — guarding against an over-eager "restrict locales to 2 letters" fix for the `values-car` collision.
  it 'prunes 3-letter legacy locale directories (e.g. values-kmr)' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      write_file(File.join(res_dir, 'values', 'strings.xml'), default_strings)
      kmr_file = File.join(res_dir, 'values-kmr', 'strings.xml')
      write_file(kmr_file, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="hello">Silav</string>
            <string name="orphan_string">Sêwî</string>
        </resources>
      XML

      pruned = run_described_fastlane_action(res_dir: res_dir)

      expect(pruned).to eq(1)
      content = File.read(kmr_file)
      expect(content).to include('name="hello"')
      expect(content).not_to include('orphan_string')
    end
  end

  it 'treats keys from `additional_source_strings_paths` as valid (flavor overlay case)' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      write_file(File.join(res_dir, 'values', 'strings.xml'), <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="flavor_only">Flavor</string>
        </resources>
      XML
      base_strings = File.join(dir, 'base', 'values', 'strings.xml')
      write_file(base_strings, default_strings)
      fr_file = File.join(res_dir, 'values-fr', 'strings.xml')
      write_file(fr_file, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="flavor_only">Saveur</string>
            <string name="hello">Bonjour</string>
            <string name="orphan_string">Orphelin</string>
        </resources>
      XML

      pruned = run_described_fastlane_action(res_dir: res_dir, additional_source_strings_paths: [base_strings])

      expect(pruned).to eq(1)
      content = File.read(fr_file)
      expect(content).to include('name="flavor_only"', 'name="hello"')
      expect(content).not_to include('orphan_string')
    end
  end

  it 'does nothing and reports zero when there are no orphaned entries' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      write_file(File.join(res_dir, 'values', 'strings.xml'), default_strings)
      fr_file = File.join(res_dir, 'values-fr', 'strings.xml')
      fr_content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <resources>
            <string name="hello">Bonjour</string>
            <string name="bye">Au revoir</string>
        </resources>
      XML
      write_file(fr_file, fr_content)

      pruned = run_described_fastlane_action(res_dir: res_dir)

      expect(pruned).to eq(0)
      expect(File.read(fr_file)).to eq(fr_content)
    end
  end

  it 'raises a clear error when the res dir has no default strings file' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      FileUtils.mkdir_p(res_dir)
      expect do
        run_described_fastlane_action(res_dir: res_dir)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Source strings file not found/)
    end
  end

  it 'raises a clear error when an additional source strings path is missing' do
    Dir.mktmpdir do |dir|
      res_dir = File.join(dir, 'res')
      write_file(File.join(res_dir, 'values', 'strings.xml'), default_strings)
      expect do
        run_described_fastlane_action(res_dir: res_dir, additional_source_strings_paths: [File.join(dir, 'missing.xml')])
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Source strings file not found/)
    end
  end
end
