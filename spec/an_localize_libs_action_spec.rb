require 'spec_helper'

describe Fastlane::Actions::AnLocalizeLibsAction do
  # This test is more of a way of ensuring `run_described_fastlane_action` handles array
  # of hashes properly than a comprehensive test for the
  # `an_localize_libs_action` action.
  #
  # Please consider expanding this test if you'll find yourself working on its
  # action.
  it 'merges the strings from the given array into the given main strings file' do
    in_tmp_dir do |tmp_dir|
      app_strings_path = File.join(tmp_dir, 'app.xml')
      File.write(app_strings_path, android_xml_with_content('<string name="a_string">test from app</string>'))

      lib1_strings_path = File.join(tmp_dir, 'lib1.xml')
      File.write(lib1_strings_path, android_xml_with_content('<string name="a_lib1_string">test from lib 1</string>'))

      lib2_strings_path = File.join(tmp_dir, 'lib2.xml')
      File.write(lib2_strings_path, android_xml_with_content('<string name="a_lib2_string">test from lib 2</string>'))

      run_described_fastlane_action(
        app_strings_path: app_strings_path,
        libs_strings_path: [
          { library: 'lib_1', strings_path: lib1_strings_path, exclusions: [] },
          { library: 'lib_2', strings_path: lib2_strings_path, exclusions: [] },
        ]
      )

      expected = <<~XML
        <string name="a_string">test from app</string>
        <string name="a_lib1_string">test from lib 1</string>
        <string name="a_lib2_string">test from lib 2</string>
      XML
      expect(File.read(app_strings_path)).to eq(android_xml_with_content(expected))
    end
  end
end

def android_xml_with_content(content)
  # I couldn't find a way to interpolate a multiline string preserving its
  # indentation in the heredoc below, so I hacked the following transformation
  # of the input that adds the desired indentation to all lines.
  #
  # The desired indentation is 4 spaces to stay aligned with the production
  # code applies when merging the XMLs.
  indented_content = content.chomp.lines.map { |l| "    #{default_indentation}#{l}" }.join

  return <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <resources xmlns:tools="http://schemas.android.com/tools">
    #{indented_content}
    </resources>
  XML
end
