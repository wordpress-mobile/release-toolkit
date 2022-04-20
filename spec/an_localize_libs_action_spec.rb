require 'spec_helper'

describe Fastlane::Actions::AnLocalizeLibsAction do
  def android_xml_with_lines(lines)
    # I couldn't find a way to interpolate a multiline string preserving its indentation in the heredoc below, so I hacked the following transformation of the input that adds the desired indentation to all lines.
    #
    # The desired indentation is 4 spaces to stay aligned with the production code applies when merging the XMLs.
    indented_content = lines.map { |l| "    #{l.chomp}" }.join("\n")

    return <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <resources xmlns:tools="http://schemas.android.com/tools">
      #{indented_content}
      </resources>
    XML
  end

  def write_android_xml(path, lines)
    File.write(path, android_xml_with_lines(lines))
  end

  describe 'merges the strings from the given array into the given main strings file' do
    it 'handles simple XMLs with no duplicates nor attributes' do
      in_tmp_dir do |tmp_dir|
        app_strings_path = File.join(tmp_dir, 'app.xml')
        File.write(app_strings_path, android_xml_with_lines(['<string name="a_string">test from app</string>']))

        lib1_strings_path = File.join(tmp_dir, 'lib1.xml')
        File.write(lib1_strings_path, android_xml_with_lines(['<string name="a_lib1_string">test from lib 1</string>']))

        lib2_strings_path = File.join(tmp_dir, 'lib2.xml')
        File.write(lib2_strings_path, android_xml_with_lines(['<string name="a_lib2_string">test from lib 2</string>']))

        run_described_fastlane_action(
          app_strings_path: app_strings_path,
          libs_strings_path: [
            { library: 'lib_1', strings_path: lib1_strings_path, exclusions: [] },
            { library: 'lib_2', strings_path: lib2_strings_path, exclusions: [] },
          ]
        )

        expected = [
          '<string name="a_string">test from app</string>',
          '<string name="a_lib1_string">test from lib 1</string>',
          '<string name="a_lib2_string">test from lib 2</string>',
        ]
        expect(File.read(app_strings_path)).to eq(android_xml_with_lines(expected))
      end
    end

    it 'keeps app value if content_override is used' do
      in_tmp_dir do |tmp_dir|
        app_strings_path = File.join(tmp_dir, 'app.xml')
        app_xml_lines = [
          '<string name="override-true" content_override="true">from app override-true</string>',
          '<string name="override-false" content_override="false">from app override-false</string>',
          '<string name="override-missing">from app override-missing</string>',
        ]
        File.write(app_strings_path, android_xml_with_lines(app_xml_lines))

        lib_strings_path = File.join(tmp_dir, 'lib.xml')
        lib_xml_lines = [
          '<string name="override-true">from lib override-true</string>',
          '<string name="override-false">from lib override-false</string>',
          '<string name="override-missing">from lib override-missing</string>',
        ]
        File.write(lib_strings_path, android_xml_with_lines(lib_xml_lines))

        run_described_fastlane_action(
          app_strings_path: app_strings_path,
          libs_strings_path: [
            { library: 'lib', strings_path: lib_strings_path, exclusions: [] },
          ]
        )

        expected = [
          '<string name="override-true" content_override="true">from app override-true</string>',
          '', '', # FIXME: Current implementation adds empty lines; we should get rid of those at some point
          '<string name="override-false">from lib override-false</string>',
          '<string name="override-missing">from lib override-missing</string>',
        ]
        expect(File.read(app_strings_path)).to eq(android_xml_with_lines(expected))
      end
    end

    it 'adds a8c-lib-src attribute if provided' do
      in_tmp_dir do |tmp_dir|
        app_strings_path = File.join(tmp_dir, 'app.xml')
        app_xml_lines = [
          '<string name="override-true" content_override="true">from app override-true</string>',
          '<string name="override-missing">from app override-missing</string>',
        ]
        File.write(app_strings_path, android_xml_with_lines(app_xml_lines))

        lib1_strings_path = File.join(tmp_dir, 'lib1.xml')
        lib1_xml_lines = [
          '<string name="override-true">from lib1 override-true</string>',
          '<string name="override-missing">from lib1 override-missing</string>',
          '<string name="lib1-key">Key only present in lib1</string>',
        ]
        File.write(lib1_strings_path, android_xml_with_lines(lib1_xml_lines))

        lib2_strings_path = File.join(tmp_dir, 'lib2.xml')
        lib2_xml_lines = [
          '<string name="override-true">from lib2 override-true</string>',
          '<string name="override-missing">from lib2 override-missing</string>',
          '<string name="lib2-key">Key only present in lib2</string>',
        ]
        File.write(lib2_strings_path, android_xml_with_lines(lib2_xml_lines))

        run_described_fastlane_action(
          app_strings_path: app_strings_path,
          libs_strings_path: [
            { library: 'lib1', strings_path: lib1_strings_path, source_id: 'lib1-id' },
            { library: 'lib2', strings_path: lib2_strings_path, source_id: 'lib2-id' },
          ]
        )

        expected = [
          '<string name="override-true" content_override="true">from app override-true</string>',
          '', # FIXME: Current implementation adds empty lines; we should get rid of those at some point
          '<string name="lib1-key" a8c-src-lib="lib1-id">Key only present in lib1</string>',
          '<string name="override-missing" a8c-src-lib="lib2-id">from lib2 override-missing</string>',
          '<string name="lib2-key" a8c-src-lib="lib2-id">Key only present in lib2</string>',
          '', # FIXME: Current implementation adds empty lines; we should get rid of those at some point
        ]
        expect(File.read(app_strings_path)).to eq(android_xml_with_lines(expected))
      end
    end

    it 'adds tools:ignore attribute when requested' do
      in_tmp_dir do |tmp_dir|
        app_strings_path = File.join(tmp_dir, 'app.xml')
        app_xml_lines = [
          '<string name="override-true" content_override="true">from app, override true</string>',
          '<string name="ignore-unused" tools:ignore="UnusedResources">from app, tools:ignore="UnusedResources"</string>',
          '<string name="ignore-x-unused-y" tools:ignore="X,UnusedResources,Y">from app, tools:ignore mix</string>',
          '<string name="ignore-x-y" tools:ignore="X,Y">from app, tools:ignore mix</string>',
        ]
        File.write(app_strings_path, android_xml_with_lines(app_xml_lines))

        lib1_strings_path = File.join(tmp_dir, 'lib1.xml')
        lib1_xml_lines = [
          '<string name="override-true">from lib1, override true</string>',
          '<string name="lib1-key">Key only present in lib1, no extra attribute</string>',
          '<string name="lib1-ignore-unused" tools:ignore="UnusedResources">Key only present in lib1, with tools:ignore attribute</string>',
          '<string name="lib1-ignore-x-y" tools:ignore="X,Y">Key only present in lib1, with tools:ignore attribute x,y</string>',
          '<string name="lib1-ignore-x-unused-y" tools:ignore="X,UnusedResources,Y">Key only present in lib1, with tools:ignore attribute x,y</string>',
        ]
        File.write(lib1_strings_path, android_xml_with_lines(lib1_xml_lines))

        lib2_strings_path = File.join(tmp_dir, 'lib2.xml')
        lib2_xml_lines = [
          '<string name="override-true">from lib2, override true</string>',
          '<string name="lib2-key">Key only present in lib2, no extra attribute</string>',
          '<string name="lib2-ignore-unused" tools:ignore="UnusedResources">Key only present in lib2, with tools:ignore attribute</string>',
          '<string name="lib2-ignore-x-y" tools:ignore="X,Y">Key only present in lib2, with tools:ignore attribute x,y</string>',
          '<string name="lib2-ignore-x-unused-y" tools:ignore="X,UnusedResources,Y">Key only present in lib2, with tools:ignore attribute x,y</string>',
        ]
        File.write(lib2_strings_path, android_xml_with_lines(lib2_xml_lines))

        run_described_fastlane_action(
          app_strings_path: app_strings_path,
          libs_strings_path: [
            { library: 'lib1', strings_path: lib1_strings_path, source_id: 'lib1', add_ignore_attr: true },
            { library: 'lib2', strings_path: lib2_strings_path, source_id: 'lib2' },
          ]
        )

        expected = [
          '<string name="override-true" content_override="true">from app, override true</string>',
          '<string name="ignore-unused" tools:ignore="UnusedResources">from app, tools:ignore="UnusedResources"</string>',
          '<string name="ignore-x-unused-y" tools:ignore="X,UnusedResources,Y">from app, tools:ignore mix</string>',
          '<string name="ignore-x-y" tools:ignore="X,Y">from app, tools:ignore mix</string>',
          '<string name="lib1-key" tools:ignore="UnusedResources" a8c-src-lib="lib1">Key only present in lib1, no extra attribute</string>',
          '<string name="lib1-ignore-unused" tools:ignore="UnusedResources" a8c-src-lib="lib1">Key only present in lib1, with tools:ignore attribute</string>',
          '<string name="lib1-ignore-x-y" tools:ignore="X,Y,UnusedResources" a8c-src-lib="lib1">Key only present in lib1, with tools:ignore attribute x,y</string>',
          '<string name="lib1-ignore-x-unused-y" tools:ignore="X,UnusedResources,Y" a8c-src-lib="lib1">Key only present in lib1, with tools:ignore attribute x,y</string>',
          '<string name="lib2-key" a8c-src-lib="lib2">Key only present in lib2, no extra attribute</string>',
          '<string name="lib2-ignore-unused" tools:ignore="UnusedResources" a8c-src-lib="lib2">Key only present in lib2, with tools:ignore attribute</string>',
          '<string name="lib2-ignore-x-y" tools:ignore="X,Y" a8c-src-lib="lib2">Key only present in lib2, with tools:ignore attribute x,y</string>',
          '<string name="lib2-ignore-x-unused-y" tools:ignore="X,UnusedResources,Y" a8c-src-lib="lib2">Key only present in lib2, with tools:ignore attribute x,y</string>',
        ]
        expect(File.read(app_strings_path)).to eq(android_xml_with_lines(expected))
      end
    end

    it 'handles exclusions list per library' do
      in_tmp_dir do |tmp_dir|
        app_strings_path = File.join(tmp_dir, 'app.xml')
        app_xml_lines = [
          '<string name="override-true" content_override="true">from app override-true</string>',
          '<string name="override-false" content_override="false">from app override-false</string>',
          '<string name="override-missing">from app override-missing</string>',
        ]
        File.write(app_strings_path, android_xml_with_lines(app_xml_lines))

        lib_strings_path = File.join(tmp_dir, 'lib.xml')
        lib_xml_lines = [
          '<string name="override-true">from lib override-true</string>',
          '<string name="override-false">from lib override-false</string>',
          '<string name="override-missing">from lib override-missing</string>',
        ]
        File.write(lib_strings_path, android_xml_with_lines(lib_xml_lines))

        run_described_fastlane_action(
          app_strings_path: app_strings_path,
          libs_strings_path: [
            { library: 'lib', strings_path: lib_strings_path, exclusions: ['override-missing'] },
          ]
        )

        expected = [
          '<string name="override-true" content_override="true">from app override-true</string>',
          '', # FIXME: Current implementation adds empty lines; we should get rid of those at some point
          '<string name="override-missing">from app override-missing</string>',
          '<string name="override-false">from lib override-false</string>',
        ]
        expect(File.read(app_strings_path)).to eq(android_xml_with_lines(expected))
      end
    end
  end
end
