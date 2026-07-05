# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Helper::StringPlaceholdersHelper do
  describe '.placeholder_signature' do
    # The exact worked examples from the issue spec — these must match byte-for-byte.
    {
      'Just text' => '',
      'Hello %@' => '1:object',
      '%1$d items in %2$@' => '1:int,2:object',
      '%2$@ told by %1$@' => '1:object,2:object',
      '100%% sure about %@' => '1:object',
      '%d likes' => '1:int'
    }.each do |value, expected_signature|
      it "returns #{expected_signature.inspect} for #{value.inspect}" do
        expect(described_class.placeholder_signature(value)).to eq(expected_signature)
      end
    end

    context 'when mapping conversion characters to argument-type classes' do
      it 'maps `%d` and `%i` to the same `int` class' do
        expect(described_class.placeholder_signature('%i likes')).to eq('1:int')
        expect(described_class.placeholder_signature('%d likes')).to eq(described_class.placeholder_signature('%i likes'))
      end

      it 'groups the other unsigned/hex integer conversions as `int`' do
        %w[%u %o %x %X].each do |specifier|
          expect(described_class.placeholder_signature("value: #{specifier}")).to eq('1:int')
        end
      end

      it 'groups all floating-point conversions as `float`' do
        %w[%f %e %E %g %G %a %A].each do |specifier|
          expect(described_class.placeholder_signature("value: #{specifier}")).to eq('1:float')
        end
      end

      it 'classes `%c`/`%C` as `char`, `%s`/`%S` as `cstring`, and `%p` as `pointer`' do
        expect(described_class.placeholder_signature('%c')).to eq('1:char')
        expect(described_class.placeholder_signature('%C')).to eq('1:char')
        expect(described_class.placeholder_signature('%s')).to eq('1:cstring')
        expect(described_class.placeholder_signature('%S')).to eq('1:cstring')
        expect(described_class.placeholder_signature('%p')).to eq('1:pointer')
      end
    end

    context 'with edge-case values' do
      it 'returns an empty signature for nil, empty, and whitespace-only values' do
        expect(described_class.placeholder_signature(nil)).to eq('')
        expect(described_class.placeholder_signature('')).to eq('')
        expect(described_class.placeholder_signature("   \n\t")).to eq('')
      end

      it 'skips the literal `%%` and does not count it as a placeholder' do
        expect(described_class.placeholder_signature('100%% done')).to eq('')
        expect(described_class.placeholder_signature('%% then %@ then %%')).to eq('1:object')
      end

      it 'treats a single literal `%` followed by a space as a literal percent, not a specifier' do
        # Common display copy uses a bare `%` ("50% off"). The printf space flag (`% d`) is deliberately
        # not recognized, so the following word is not mistaken for a space-flagged specifier.
        expect(described_class.placeholder_signature('50% off')).to eq('')
        expect(described_class.placeholder_signature('100% done')).to eq('')
        expect(described_class.placeholder_signature('Battery at 50% and charging')).to eq('')
        expect(described_class.placeholder_signature('100% complete.')).to eq('')
        # A real placeholder alongside literal-percent copy keeps only the real one.
        expect(described_class.placeholder_signature('You saved %@ — 50% off')).to eq('1:object')
      end

      it 'treats the write-back `%n` conversion as a literal, not a placeholder' do
        # `%n` consumes no printable argument and has no place in a localized string, so it is not
        # recognized as a specifier (and never classed as a bogus `n` type).
        expect(described_class.placeholder_signature('%n')).to eq('')
        expect(described_class.placeholder_signature('Press %n to continue')).to eq('')
      end

      it 'recognizes the C "precision 0" form `%.f` (a dot with no digits) as a float' do
        # `.` followed by zero digits is valid (precision 0); it must not drop the placeholder.
        expect(described_class.placeholder_signature('%.f km')).to eq('1:float')
        expect(described_class.placeholders_compatible?('%.1f km', '%.f km')).to be(true)
      end

      it 'ignores width, precision, and length modifiers when classing the type' do
        expect(described_class.placeholder_signature('%5d')).to eq('1:int')
        expect(described_class.placeholder_signature('%.2f')).to eq('1:float')
        expect(described_class.placeholder_signature('%-8.3f')).to eq('1:float')
        expect(described_class.placeholder_signature('%1$ld')).to eq('1:int')
        expect(described_class.placeholder_signature('%lld')).to eq('1:int')
      end

      it 'numbers non-positional specifiers by order of appearance' do
        expect(described_class.placeholder_signature('%@ and %d and %f')).to eq('1:object,2:int,3:float')
      end

      it 'sorts positional specifiers by their explicit position' do
        expect(described_class.placeholder_signature('%3$@ %1$d %2$f')).to eq('1:int,2:float,3:object')
      end

      it 'handles non-ASCII copy and escaped quotes/backslashes around the placeholders' do
        expect(described_class.placeholder_signature('「%@」を削除しますか？')).to eq('1:object')
        expect(described_class.placeholder_signature('Path \\"%@\\" — %d items\\\\')).to eq('1:object,2:int')
      end

      it 'is deterministic for the rare/invalid mix of positional and non-positional specifiers' do
        signature = described_class.placeholder_signature('%1$@ and %d')
        expect(signature).to eq('1:object,2:int')
        # Calling it again on the same input yields the same result.
        expect(described_class.placeholder_signature('%1$@ and %d')).to eq(signature)
      end
    end

    context 'with a positional argument referenced more than once' do
      # `%1$@ … %1$@` consumes a single argument (printed twice), so it must collapse to one slot and
      # stay compatible with a single `%1$@` — repeating an argument is not a placeholder change.
      it 'collapses a repeated positional argument to a single slot' do
        expect(described_class.placeholder_signature('%1$@ and %1$@')).to eq('1:object')
        expect(described_class.placeholder_signature('%1$@')).to eq('1:object')
      end

      it 'collapses three references to the same positional argument' do
        expect(described_class.placeholder_signature('%1$d, %1$d and %1$d')).to eq('1:int')
      end

      it 'keeps the other arguments when one positional argument repeats' do
        expect(described_class.placeholder_signature('%1$@ told %2$d, then %1$@ again')).to eq('1:object,2:int')
      end

      it 'does not collapse distinct non-positional placeholders of the same type' do
        # Non-positional args are consumed in order, so two `%@` are two separate arguments.
        expect(described_class.placeholder_signature('%@ and %@')).to eq('1:object,2:object')
      end
    end

    context 'with thousands-grouping flags' do
      # The C/POSIX `'` and Java/Android `,` grouping flags must be recognized, otherwise the whole
      # specifier fails to match and silently vanishes from the signature — masking a real change.
      it 'recognizes the `,` (Java/Android) and `\'` (C/POSIX) grouping flags as a normal `int`' do
        expect(described_class.placeholder_signature('%,d')).to eq('1:int')
        expect(described_class.placeholder_signature("%'d")).to eq('1:int')
        expect(described_class.placeholder_signature('%,12d')).to eq('1:int')
        expect(described_class.placeholder_signature('%1$,d in %2$@')).to eq('1:int,2:object')
      end

      it 'treats a grouped int the same as a plain int (the flag does not change the argument type)' do
        expect(described_class.placeholder_signature('%,d')).to eq(described_class.placeholder_signature('%d'))
      end
    end

    context 'with `*` dynamic width or precision' do
      # `%*d`/`%.*f` consume an extra `int` (the width/precision) that the one-slot-per-specifier
      # model can't represent, so they are intentionally left unrecognized rather than silently
      # treated as compatible with a fixed-width/precision specifier.
      it 'does not recognize a `*` specifier (so it cannot masquerade as its fixed counterpart)' do
        expect(described_class.placeholder_signature('%.*f km')).to eq('')
        expect(described_class.placeholder_signature('%*d items')).to eq('')
      end
    end
  end

  describe '.placeholders_compatible?' do
    # The exact compatibility table from the issue spec.
    [
      ['Hello %@', 'Hi %@', true],                       # text-only change
      ['%1$@ said %2$@', '%2$@ told by %1$@', true],     # positional reorder, same types
      ['%d likes', '%@ likes', false],                  # int → object
      ['%1$d in %2$@', '%1$d only', false],             # dropped a placeholder
    ].each do |old_value, new_value, expected|
      it "returns #{expected} for #{old_value.inspect} → #{new_value.inspect}" do
        expect(described_class.placeholders_compatible?(old_value, new_value)).to be(expected)
      end
    end

    it 'treats `%d` ↔ `%i` as compatible (same argument type)' do
      expect(described_class.placeholders_compatible?('%d apples', '%i apples')).to be(true)
    end

    it 'treats two placeholder-free strings as compatible' do
      expect(described_class.placeholders_compatible?('Old copy', 'New copy')).to be(true)
    end

    it 'treats adding a placeholder to a placeholder-free string as incompatible' do
      expect(described_class.placeholders_compatible?('Done', 'Done %@')).to be(false)
    end

    it 'treats repeating a positional argument as compatible (the same argument consumed twice)' do
      expect(described_class.placeholders_compatible?('%1$@', '%1$@ and %1$@')).to be(true)
    end

    it 'treats adding a genuinely new positional argument as incompatible' do
      expect(described_class.placeholders_compatible?('%1$@', '%1$@ in %2$@')).to be(false)
    end

    it 'treats adding or removing a thousands-grouping flag as compatible (same `int` argument)' do
      expect(described_class.placeholders_compatible?('%d items', '%,d items')).to be(true)
    end

    it 'still catches a count change between two grouped-int placeholders' do
      # Both sides use the `,` grouping flag; without flag support both would collapse to an empty
      # signature and this translation-breaking 2 → 1 count change would be silently passed.
      expect(described_class.placeholders_compatible?('%,d of %,d', '%,d done')).to be(false)
    end

    it 'flags a change between a fixed and a `*` dynamic width/precision specifier' do
      # `%.1f km` consumes one float; `%.*f km` consumes an int (precision) + a float. Treating them
      # as compatible would let an existing translation render the precision where the value belongs.
      expect(described_class.placeholders_compatible?('%.1f km', '%.*f km')).to be(false)
      expect(described_class.placeholders_compatible?('%5d items', '%*d items')).to be(false)
    end
  end

  describe '.incompatible_placeholder_changes' do
    it 'returns an empty array when nothing changed incompatibly' do
      old_strings = { 'greeting' => 'Hello %@', 'count' => '%d items' }
      new_strings = { 'greeting' => 'Hi %@', 'count' => '%d items' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq([])
    end

    it 'does not report a positional reorder of equivalently-typed args' do
      old_strings = { 'attribution' => '%1$@ said %2$@' }
      new_strings = { 'attribution' => '%2$@ told by %1$@' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq([])
    end

    it 'reports a key whose argument type changed, with full detail' do
      old_strings = { 'likes' => '%d likes' }
      new_strings = { 'likes' => '%@ likes' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq(
        [{ key: 'likes', old: '%d likes', new: '%@ likes', old_signature: '1:int', new_signature: '1:object' }]
      )
    end

    it 'reports a key whose placeholder count changed' do
      old_strings = { 'msg' => '%1$d in %2$@' }
      new_strings = { 'msg' => '%1$d only' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq(
        [{ key: 'msg', old: '%1$d in %2$@', new: '%1$d only', old_signature: '1:int,2:object', new_signature: '1:int' }]
      )
    end

    it 'still catches a real placeholder removal when the new copy contains a literal `%`' do
      # The translation-breaking change: `%d` is dropped, but the new copy has a bare `%` ("100% done").
      # If `% d` were parsed as a phantom int specifier, the signatures would both be `1:int` and this
      # removal would be silently masked — the exact failure this check exists to catch.
      old_strings = { 'progress' => '%d items left' }
      new_strings = { 'progress' => '100% done' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq(
        [{ key: 'progress', old: '%d items left', new: '100% done', old_signature: '1:int', new_signature: '' }]
      )
    end

    it 'does not flag a copy edit on a string that contains a literal `%`' do
      # A bare `%` followed by a space is literal-percent copy, so editing the surrounding words is not a
      # placeholder change and must not be reported.
      old_strings = { 'sale' => '50% off' }
      new_strings = { 'sale' => '50% off today only' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq([])
    end

    it 'ignores keys that were added or removed' do
      old_strings = { 'shared' => 'Hello %@', 'removed' => '%d gone' }
      new_strings = { 'shared' => 'Hi %@', 'added' => '%d new' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq([])
    end

    it 'returns one entry per incompatible key, sorted by key' do
      old_strings = { 'zebra' => '%@', 'alpha' => '%d', 'stable' => 'Hi %@' }
      new_strings = { 'zebra' => '%d', 'alpha' => '%@', 'stable' => 'Hello %@' }
      result = described_class.incompatible_placeholder_changes(old_strings, new_strings)
      expect(result.map { |change| change[:key] }).to eq(%w[alpha zebra])
    end

    it 'does not flag a copy edit that merely repeats an existing positional argument' do
      old_strings = { 'cta' => 'Open %1$@' }
      new_strings = { 'cta' => 'Open %1$@ — and again, %1$@!' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq([])
    end

    it 'still flags adding a genuinely new argument' do
      old_strings = { 'cta' => 'Open %1$@' }
      new_strings = { 'cta' => 'Open %1$@ in %2$@' }
      expect(described_class.incompatible_placeholder_changes(old_strings, new_strings)).to eq(
        [{ key: 'cta', old: 'Open %1$@', new: 'Open %1$@ in %2$@', old_signature: '1:object', new_signature: '1:object,2:object' }]
      )
    end
  end

  describe '.mixed_operators?' do
    it 'is false for an all-non-positional value' do
      expect(described_class.mixed_operators?('%@ and %d and %f')).to be(false)
    end

    it 'is false for an all-positional value' do
      expect(described_class.mixed_operators?('%2$@ and %1$d')).to be(false)
    end

    it 'is false for a value with no placeholders (including a literal `%%`)' do
      expect(described_class.mixed_operators?('Just text')).to be(false)
      expect(described_class.mixed_operators?('100%% literal')).to be(false)
      expect(described_class.mixed_operators?(nil)).to be(false)
    end

    it 'is false for an all-positional value that also contains a literal `%`' do
      # A bare `%` ("50% off") must not be parsed as a phantom non-positional specifier; otherwise this
      # valid all-positional string would look mixed and the action would abort the lane on valid copy.
      expect(described_class.mixed_operators?('%1$@ uploaded — 50% off')).to be(false)
      expect(described_class.mixed_operators?('%1$@ done, 5% saved')).to be(false)
    end

    it 'is true when a value mixes positional and non-positional specifiers' do
      expect(described_class.mixed_operators?('%2$@ and %d')).to be(true)
      expect(described_class.mixed_operators?('%@ and %1$d')).to be(true)
    end
  end
end
