require 'spec_helper'

module StringsFileValidator
end

def extract_key(line:)
  # Notice the [\S\s] which accounts for escaped characters, which are
  # allowed according to the `.strings` spec.
  #
  # TODO: 👆 That's not accurate
  #
  # See
  # https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html#//apple_ref/doc/uid/10000051i-CH6-SW13
  # (Using Special Characters in String Resources)
  regexp = /^\s*"([^"]*[\S\s]*[^"])"\s*=/
  key_range_offset0 = line.match(regexp)&.offset(0)
  key_range_offset1 = line.match(regexp)&.offset(1)
  # puts "match: #{line.match(regexp)}"
  # puts "range 0: #{key_range_offset0}"
  # puts "other 1: #{key_range_offset1}"

  return nil if key_range_offset0.nil?

  # puts "key at offest 0: #{line[key_range_offset0[0]...key_range_offset0[1]]}"
  # puts "key at offest 1: #{line[key_range_offset1[0]...key_range_offset1[1]]}"
  line[key_range_offset1[0]...key_range_offset1[1]]
end

def find_duplicated_keys(file:)
  found_keys = {}
  duplicated_keys = []
  file.lines.each_with_index do |line, index|
    key = extract_key(line: line)

    next if key.nil?

    # Check if that key was already encountered in the past
    existing = found_keys[key]

    puts key
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
      /* Special case: \"%@\" can be tricky to detect */
      "The Google account \"%@\" doesn't match any account on WordPress.com" = "localized translation here";
      /* A red herring that might be seen as duplicate to the previous one if our RegExp does not correctly account for escaped quotes */
      "The Google account \"%@\" is invalid" = "localized translation here";
      /* Duplicated \"%@\" */
      "key with \"%@\" character" = "localized translation here";
      "key with \"%@\" character" = "localized translation here";
      /* This is just a check for Gio's implementation. We might want to remove it? */
      "key with trailing spaces " = "localized translation here";
      "key with trailing spaces " = "localized translation here";
    PO

    expect(find_duplicated_keys(file: dummy_text)).to match_array [
      'dup1', 'dup2', 'dup3', 'dup4',
      "\U0025 key", "\U0026 key",
      'The Google account ',
    ]
  end
end
