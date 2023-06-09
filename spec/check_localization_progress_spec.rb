require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::CheckTranslationProgressAction do
  before do
    allow(FastlaneCore::UI).to receive(:message)
    allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
  end

  it 'does not fail when all the languages are above the set threshold' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '2,078', fuzzy: '2', waiting: '3', untranslated: '4', progress: '99' },
      { lang_name: 'spanish', lang_code: 'es', current: '2,085', fuzzy: '0', waiting: '0', untranslated: '2', progress: '99' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    expect(FastlaneCore::UI).to receive(:success).with('Done')

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      language_codes: %w[ar de es],
      min_acceptable_translation_percentage: 99,
      abort_on_violations: true,
      skip_confirm: false
    )

    expect(stub).to have_been_made.once
  end

  it 'fails on missing data for a language' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '2,078', fuzzy: '2', waiting: '3', untranslated: '4', progress: '99' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    expect(FastlaneCore::UI).to receive(:abort_with_message!).with("Can't get data for language es")
    # Since the action doesn't actually fail during the test, fake error messages can be raised
    allow(FastlaneCore::UI).to receive(:abort_with_message!)

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      # Invoke with 'es' which is not in the mocked message
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: true,
      skip_confirm: true
    )

    expect(stub).to have_been_made.once
  end

  it 'fails on missing data' do
    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 404,
             body: ''
           )

    expect(FastlaneCore::UI).to receive(:abort_with_message!).with('Can\'t retrieve data from https://translate.wordpress.org/projects/apps/my-test-project/dev')
    # Since the action doesn't actually fail during the test, fake error messages can be raised
    allow(FastlaneCore::UI).to receive(:abort_with_message!)

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      # Invoke with 'es' which is not in the mocked message
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: true,
      skip_confirm: true
    )

    expect(stub).to have_been_made.once
  end

  it 'fails when one the language is below the set threshold' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '1,078', fuzzy: '2', waiting: '1003', untranslated: '4', progress: '51' },
      { lang_name: 'spanish', lang_code: 'es', current: '2,085', fuzzy: '0', waiting: '0', untranslated: '2', progress: '99' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    expect(FastlaneCore::UI).to receive(:abort_with_message!).with('de is translated 51% which is under the required 99%.')

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: true,
      skip_confirm: true
    )

    expect(stub).to have_been_made.once
  end

  it 'does not fail when one the language is above the set threshold, but there are updates waiting for review' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '2,087', fuzzy: '0', waiting: '103', untranslated: '0', progress: '99' },
      { lang_name: 'spanish', lang_code: 'es', current: '2,085', fuzzy: '0', waiting: '0', untranslated: '2', progress: '99' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    expect(FastlaneCore::UI).to receive(:success).with('Done')

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: true,
      skip_confirm: true
    )

    expect(stub).to have_been_made.once
  end

  it 'prints the report and asks user confirmation when one the language is below the threshold and aborting is disabled' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '1,078', fuzzy: '2', waiting: '1003', untranslated: '4', progress: '51' },
      { lang_name: 'spanish', lang_code: 'es', current: '2,085', fuzzy: '0', waiting: '0', untranslated: '2', progress: '99' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    confirm_message = <<~MSG
      The translations for the following languages are below the 99% threshold:
       - de is at 51%.
      Do you want to continue?
    MSG

    expect(FastlaneCore::UI).to receive(:confirm).with(confirm_message.strip)
    expect(FastlaneCore::UI).to receive(:abort_with_message!).with('Aborted by user!')

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: false,
      skip_confirm: false
    )

    expect(stub).to have_been_made.once
  end

  it 'prints the report and asks user confirmation when multiples languages are below the threshold and aborting is disabled' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '1,078', fuzzy: '2', waiting: '1003', untranslated: '4', progress: '51' },
      { lang_name: 'spanish', lang_code: 'es', current: '1,585', fuzzy: '0', waiting: '0', untranslated: '502', progress: '75' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    confirm_message = <<~MSG
      The translations for the following languages are below the 99% threshold:
       - de is at 51%.
       - es is at 75%.
      Do you want to continue?
    MSG

    expect(FastlaneCore::UI).to receive(:confirm).with(confirm_message.strip)
    expect(FastlaneCore::UI).to receive(:abort_with_message!).with('Aborted by user!')

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: false,
      skip_confirm: false
    )

    expect(stub).to have_been_made.once
  end

  it 'prints the report and continues when one the language is below the threshold, aborting is disabled and confirmation is skipped' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '1,078', fuzzy: '2', waiting: '1003', untranslated: '4', progress: '51' },
      { lang_name: 'spanish', lang_code: 'es', current: '1,585', fuzzy: '0', waiting: '0', untranslated: '502', progress: '75' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    confirm_message = <<~MSG
      The translations for the following languages are below the 99% threshold:
       - de is at 51%.
       - es is at 75%.
    MSG

    expect(FastlaneCore::UI).to receive(:important).with(confirm_message)
    expect(FastlaneCore::UI).to receive(:success).with('Done')

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: false,
      skip_confirm: true
    )

    expect(stub).to have_been_made.once
  end

  it 'prints the report and continues when multiple languages are below the threshold, aborting is disabled and confirmation is skipped' do
    langs = [
      { lang_name: 'arabic', lang_code: 'ar', current: '2,087', fuzzy: '0', waiting: '0', untranslated: '0', progress: '100' },
      { lang_name: 'german', lang_code: 'de', current: '1,078', fuzzy: '2', waiting: '1003', untranslated: '4', progress: '51' },
      { lang_name: 'spanish', lang_code: 'es', current: '2,085', fuzzy: '0', waiting: '0', untranslated: '2', progress: '100' },
    ]

    stub = stub_request(
      :get,
      'https://translate.wordpress.org/projects/apps/my-test-project/dev'
    )
           .to_return(
             status: 200,
             body: generate_glotpress_response_body(languages: langs)
           )

    confirm_message = <<~MSG
      The translations for the following languages are below the 99% threshold:
       - de is at 51%.
    MSG

    expect(FastlaneCore::UI).to receive(:important).with(confirm_message)
    expect(FastlaneCore::UI).to receive(:success).with('Done')

    described_class.run(
      glotpress_url: 'https://translate.wordpress.org/projects/apps/my-test-project/dev',
      language_codes: 'ar de es'.split(),
      min_acceptable_translation_percentage: 99,
      abort_on_violations: false,
      skip_confirm: true
    )

    expect(stub).to have_been_made.once
  end
end

def generate_glotpress_response_body(languages:)
  response = ''
  response << generate_glotpress_response_header()
  languages.each do |language|
    response << generate_glotpress_response_for_language(
      lang: language[:lang_name],
      lang_code: language[:lang_code],
      current: language[:current],
      fuzzy: language[:fuzzy],
      waiting: language[:waiting],
      untranslated: language[:untranslated],
      progress: language[:progress]
    )
  end

  response << generate_glotpress_response_footer()
  response
end

def generate_glotpress_response_header
  <<~HEADER
    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml" dir="ltr" lang="en-US">
    <head>
    <meta charset="utf-8" />
    <!--
    <meta property="fb:page_id" content="6427302910" />
    -->
    <title>Development &lt; GlotPress &mdash; WordPress.org</title>
    <meta name="referrer" content="always">
    <link rel='stylesheet' id='admin-bar-css'  href='https://translate.wordpress.org/wp-includes/css/admin-bar.min.css?ver=5.8-alpha-50943' media='all' />
    <script src='https://translate.wordpress.org/wp-includes/js/hoverintent-js.min.js?ver=2.2.1' id='hoverintent-js-js'></script>
    </head>
    <body>
        <tbody>
  HEADER
end

def generate_glotpress_response_for_language(lang:, lang_code:, current:, fuzzy:, waiting:, untranslated:, progress:)
  res = "<tr class=\"odd\">\n"
  res << generate_glotpress_response_header_for_language(lang: lang, lang_code: lang_code, progress: progress)
  res << generate_glotpress_response_for_language_status(lang_code: lang_code, status_main: 'translated', status: 'current', string_count: current)
  res << generate_glotpress_response_for_language_status(lang_code: lang_code, status_main: 'fuzzy', status: 'fuzzy', string_count: fuzzy)
  res << generate_glotpress_response_for_language_status(lang_code: lang_code, status_main: 'untranslated', status: 'untranslated', string_count: waiting)
  res << generate_glotpress_response_for_language_status(lang_code: lang_code, status_main: 'waiting', status: 'waiting', string_count: untranslated)
  res <<	'</tr>'
end

def generate_glotpress_response_header_for_language(lang:, lang_code:, progress:)
  res = "<td>\n"
  res << "<strong><a href=\"/projects/apps/whatever/dev/#{lang_code}/default/\">#{lang}</a></strong>\n"
  res << "<span class=\"bubble morethan90\">#{progress}%</span>\n" if progress.to_i > 90
  res << "</td>\n"
  res << "<td class=\"stats percent\">#{progress}%</td>\n"
end

def generate_glotpress_response_for_language_status(lang_code:, status_main:, status:, string_count:)
  res = "<td class=\"stats #{status_main}\" title=\"#{status_main}\">\n"
  res << "<a href=\"/projects/apps/whatever/dev/#{lang_code}/default/?filters%5Btranslated%5D=yes&#038;filters%5Bstatus%5D=#{status}\">#{string_count}</a></td>"

  res
end

def generate_glotpress_response_footer
  <<~FOOTER
      </tbody>
    </body>
    </html>
  FOOTER
end
