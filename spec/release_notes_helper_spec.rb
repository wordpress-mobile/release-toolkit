require 'tmpdir'
require_relative 'spec_helper'

describe Fastlane::Helper::ReleaseNotesHelper do
  it 'adds a new section on top if there are no header comments' do
    run_release_notes_test ''
  end

  it 'adds a new section after any `//` comments on top' do
    run_release_notes_test <<~HEADER
      // This is a header
      // that we want to keep pinned on top.

    HEADER
  end

  it 'adds a new section after any `***` comments on top' do
    run_release_notes_test <<~HEADER
      *** This is a header
      *** that we want to keep pinned on top.

    HEADER
  end

  it 'adds a new section after any `#` comments on top' do
    run_release_notes_test <<~HEADER
      # This is a Markdown header
      ## This is another kind of Markdown header
      ### This is an H3 Markdown header

    HEADER
  end

  it 'adds a new section after any `- ` comments on top' do
    run_release_notes_test <<~HEADER
      - This is a line item
      - And this is another line item that we want to include

    HEADER
  end

  it 'does consider empty lines as header' do
    run_release_notes_test("\n\n\n")
  end

  it 'adds a new section only after a mix of `//` and `***` comments and empty lines' do
    run_release_notes_test <<~HEADER
      // This is a header
      // that we want to keep pinned on top.

      *** It contains some mixed style of comments
      *** with both double-slash style comment lines
      *** and triple-star style ones.

      - List item
      - Another list item

      # Markdown Header
      ## H2 Markdown Header




      // It also contains some empty lines we want to count as part of the pinned lines.

    HEADER
  end

  it 'does not consider ** as comments' do
    prefix = <<~NOT_HEADER
      ** This is not a comment
      *** This is; but it's after the non-comment line above, so not at the very top of the file
      *** and should hence not be considered part of the pinned header to be skipped.
    NOT_HEADER
    run_release_notes_test('', prefix + FAKE_CONTENT)
  end
end

FAKE_CONTENT = <<~CONTENT.freeze
  1.2.3
  -----
  - Item 1 for v1.2.3
  - Item 2 for v1.2.3

  // Comment in the middle

  1.2.2
  -----
  - Item 1 for v1.2.2
  - Item 2 for v1.2.2
CONTENT

NEW_SECTION = <<~CONTENT.freeze
  New Section
  -----


CONTENT

def run_release_notes_test(header, post_header_content = FAKE_CONTENT)
  Dir.mktmpdir('a8c-release-notes-test-') do |dir|
    tmp_file = File.join(dir, 'TEST-REL-NOTES.txt')
    File.write(tmp_file, header + post_header_content)

    Fastlane::Helper::ReleaseNotesHelper.add_new_section(path: tmp_file, section_title: 'New Section')

    new_content = File.read(tmp_file)
    expect(new_content).to eq(header + NEW_SECTION + post_header_content)
  end
end
