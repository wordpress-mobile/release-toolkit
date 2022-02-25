require 'spec_helper'

module StringsFileValidator
end

def extract_key(line:)
  # The `gsub(\\./, '..')` call replaces any backslash-escape (\n, \r, \\, \",
  # …) with 2 different characters that won't mess up our RegEx instead
  key_range =
    line
    .gsub(/\\./, '..')
    .match(/^\s*"([^"]*)"/)&.offset(1)

  return nil if key_range.nil?

  # Return the same range of character than the one found, but from the
  # original string (pre-backslash-escape-replacements)
  return line[key_range[0]...key_range[1]]
end

def find_duplicated_keys(file:)
  found_keys = {}
  duplicated_keys = []
  file.lines.each_with_index do |line, index|
    key = extract_key(line: line)

    next if key.nil?

    # Check if that key was already encountered in the past
    existing = found_keys[key]

    duplicated_keys.append(key) unless existing.nil?
    puts "warning: key `#{key}` on line #{index + 1} is a duplicate of a similar key found on line #{existing + 1}" unless existing.nil?

    # Memorize the line at which this key appeared in the source `.strings`
    # file
    found_keys[key] = index
  end

  duplicated_keys
end

describe StringsFileValidator do
  it 'raises when there are duplicated keys' do
    dummy_text = <<~PO
      /* A comment */
      "key" = "localized translation here";
      /* A value with escaped characters */
      "key.key" = "Hello \"World\"!";
      /* Keys with escaped characters */
      "it's a \" = " = "trap";
      "it's another \\" = "trap";
      /* A multi-line value */
      "error.message" = "One line.
      Another line.";
      /* A multi-line
       comment
      */
      "comment" = "comment"
      /* Below are two keys with leading spaces to test against malformatted files */
       "space" = "localized translation here";
        "more.space" = "localized translation here";
      /* Below are some entries with unusual spaces between key and value to test against malformed files */
      "nospace"="localized translation here";
      "space.nospace" ="localized translation here";
      "nospace.space"= "localized translation here";
      "lots of spaces"   =  "localized translation here";
      /*
       * Duplicated keys
       */
      /* Consecutive duplicated keys */
      "dup1" = "localized translation here";
      "dup1" = "localized translation here";
      /* Duplicated keys with other entries in between */
      "dup2" = "localized translation here";
      "not dup" = "localized translation here";
      "dup2" = "localized translation here";
      "dup3" = "localized translation here";
      "not dup 2" = "localized translation here";
      "not dup 3" = "localized translation here";
      "dup3" = "localized translation here";
      /* Duplicated keys with different translations are still duplicated */
      "dup4" = "a translation";
      "dup4" = "a different translation";
      /* Duplicated comments should be ignored */
      "key with dup comment" = "localized translation here";
      /* Duplicated comments should be ignored */
      "different key with dup comment" = "localized translation here";
      /* Unicode codepoint escape — see https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html#//apple_ref/doc/uid/10000051i-CH6-SW13 */
      /* Consecutive... */
      "\U0025 key" = "\U0025 is the % symbol";
      "\U0025 key" = "\U0025 is the % symbol";
      /* ...and not consecutive */
      "\U0026 key" = "\U0025 is the & symbol";
      "unicode\U0020key" = "\U0020 is the space character";
      "\U0026 key" = "\U0025 is the & symbol";
      /* Special case: \"%@\" can be tricky to detect in RegExp */
      "The Google account \"%@\" doesn't match any account on WordPress.com" = "localized translation here";
      /* A red herring that might be seen as duplicate to the previous one if our RegExp does not correctly account for escaped quotes */
      "The Google account \"%@\" is invalid" = "localized translation here";
    PO

    expect(find_duplicated_keys(file: dummy_text)).to match_array [
      'dup1', 'dup2', 'dup3', 'dup4',
      "\U0025 key", "\U0026 key",
      'The Google account ',
    ]
  end
end
