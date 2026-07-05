# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::IosLintLocalizationPlaceholderChangesAction do
  before do
    # Prevent the action from actually aborting the (test) lane when violations are found.
    allow(FastlaneCore::UI).to receive(:abort_with_message!)
  end

  # Writes `old` and `new` as ASCII-plist `.strings` files in a temporary
  # directory and runs the action against them.
  def lint_placeholder_changes(old:, new:, **extra_params)
    in_tmp_dir do |tmp_dir|
      old_file = File.join(tmp_dir, 'old.strings')
      new_file = File.join(tmp_dir, 'new.strings')
      File.write(old_file, old)
      File.write(new_file, new)
      run_described_fastlane_action({ old_file: old_file, new_file: new_file }.merge(extra_params))
    end
  end

  it 'returns no violations and does not abort when placeholders are unchanged' do
    expect(FastlaneCore::UI).not_to receive(:abort_with_message!)

    result = lint_placeholder_changes(
      old: <<~OLD,
        "greeting" = "Hello %@";
        "count" = "%d items";
      OLD
      new: <<~NEW
        "greeting" = "Hi %@";
        "count" = "%d items remaining";
      NEW
    )

    expect(result).to eq([])
  end

  it 'prints a success message when there are no incompatible changes' do
    # The lane runner also emits `UI.success` ("Driving the lane …"), so capture all of them and
    # assert ours is among them rather than constraining every call.
    messages = []
    allow(FastlaneCore::UI).to receive(:success) { |m| messages << m }

    lint_placeholder_changes(old: '"greeting" = "Hi %@";', new: '"greeting" = "Hello %@";')

    expect(messages.join("\n")).to include('No incompatible placeholder changes')
  end

  it 'reports and aborts when an existing key changes its placeholder type' do
    expect(FastlaneCore::UI).to receive(:abort_with_message!)

    result = lint_placeholder_changes(
      old: '"likes" = "%d likes";',
      new: '"likes" = "%@ likes";'
    )

    expect(result).to eq(
      [{ key: 'likes', old: '%d likes', new: '%@ likes', old_signature: '1:int', new_signature: '1:object' }]
    )
  end

  it 'actually halts the lane (raises) when it aborts on violations, instead of returning' do
    # The `before` block stubs `abort_with_message!` to a no-op so the other examples can inspect the
    # return value. Here we let the real one run to prove the abort genuinely stops the lane: in
    # production `UI.abort_with_message!` raises, so the action must not fall through to its `return`.
    allow(FastlaneCore::UI).to receive(:abort_with_message!).and_call_original

    expect do
      lint_placeholder_changes(old: '"likes" = "%d likes";', new: '"likes" = "%@ likes";')
    end.to raise_error(/changed their format placeholders incompatibly/)
  end

  it 'ignores added and removed keys, only flagging changes to keys present in both' do
    result = lint_placeholder_changes(
      old: <<~OLD,
        "shared" = "Hello %@";
        "removed" = "%d gone";
      OLD
      new: <<~NEW
        "shared" = "Hi %@";
        "added" = "%d new";
      NEW
    )

    expect(result).to eq([])
  end

  it 'does not abort when `abort_on_violations` is false but still returns the violations' do
    expect(FastlaneCore::UI).not_to receive(:abort_with_message!)

    result = lint_placeholder_changes(
      old: '"msg" = "%1$d in %2$@";',
      new: '"msg" = "%1$d only";',
      abort_on_violations: false
    )

    expect(result).to eq(
      [{ key: 'msg', old: '%1$d in %2$@', new: '%1$d only', old_signature: '1:int,2:object', new_signature: '1:int' }]
    )
  end

  it 'fails with a friendly error when a file does not exist' do
    in_tmp_dir do |tmp_dir|
      old_file = File.join(tmp_dir, 'old.strings')
      File.write(old_file, '"key" = "value";')
      missing_file = File.join(tmp_dir, 'does-not-exist.strings')

      expect do
        run_described_fastlane_action(old_file: old_file, new_file: missing_file)
      end.to raise_error(/not found/)
    end
  end

  context 'when a source file defines the same key more than once' do
    # `plutil` keeps only the *last* value for a duplicated key, so without this guard the
    # incompatible first definition below would be silently discarded and the change missed.
    it 'aborts with an explanation, before the (now-unreliable) comparison can hide the change' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/defined more than once/)

      result = lint_placeholder_changes(
        old: '"likes" = "%d likes";',
        new: <<~NEW
          "likes" = "%@ likes";
          "likes" = "%d likes";
        NEW
      )

      expect(result).to eq([])
    end

    it 'halts on the duplicate key *before* the placeholder comparison runs' do
      # Here the duplicated *last* value (`%@ likes`) is itself incompatible with old (`%d likes`), so a
      # comparison run first would raise about a placeholder change. Letting the real abort run (rather
      # than the no-op stub) and asserting we get the duplicate-key error instead proves the duplicate
      # guard halts the action ahead of the now-unreliable comparison — not merely that both happen to
      # yield `[]`.
      allow(FastlaneCore::UI).to receive(:abort_with_message!).and_call_original

      expect do
        lint_placeholder_changes(
          old: '"likes" = "%d likes";',
          new: <<~NEW
            "likes" = "%@ likes";
            "likes" = "%@ likes";
          NEW
        )
      end.to raise_error(/defined more than once/)
    end

    it 'lists each duplicated key and its line numbers in the error output' do
      errors = []
      allow(FastlaneCore::UI).to receive(:error) { |m| errors << m }

      lint_placeholder_changes(
        old: '"likes" = "%d likes";',
        new: <<~NEW
          "dup" = "a";
          "dup" = "b";
        NEW
      )

      expect(errors.join("\n")).to include('defines 1 key(s) more than once')
      expect(errors.join("\n")).to include('`dup` at lines 1, 2')
    end

    it 'also catches duplicates in the old file' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/defined more than once/)

      lint_placeholder_changes(
        old: <<~OLD,
          "greeting" = "Hello %@";
          "greeting" = "Hello %@";
        OLD
        new: '"greeting" = "Hello %@";'
      )
    end

    it 'aborts on duplicate keys even when `abort_on_violations` is false (they corrupt the comparison itself)' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/defined more than once/)

      lint_placeholder_changes(
        old: '"k" = "%@";',
        new: <<~NEW,
          "k" = "%@";
          "k" = "%@";
        NEW
        abort_on_violations: false
      )
    end

    it 'does not check for duplicates when `check_duplicate_keys` is false (plutil silently keeps the last value)' do
      expect(FastlaneCore::UI).not_to receive(:abort_with_message!)

      result = lint_placeholder_changes(
        old: '"likes" = "%d likes";',
        new: <<~NEW,
          "likes" = "%@ likes";
          "likes" = "%d likes";
        NEW
        check_duplicate_keys: false
      )

      expect(result).to eq([]) # the incompatible first definition is silently discarded
    end

    it 'detects duplicates even when the keys are unquoted (`InfoPlist.strings` style)' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/defined more than once/)

      lint_placeholder_changes(
        old: "NSHumanReadableCopyright = \"© %@\";\n",
        new: <<~NEW
          NSHumanReadableCopyright = "© %@";
          NSHumanReadableCopyright = "© %d";
        NEW
      )
    end
  end

  context 'when a `:text` file parses for `plutil` but the scanner cannot tokenize it' do
    # An old-style plist value can be a nested dictionary (`"k" = { a = b; };`) — valid input that
    # `plutil` parses, but not a flat `.strings` file the duplicate-key scanner can tokenize. The check
    # must not silently skip and compare blindly: each key being defined once is a precondition for a
    # reliable comparison, so we fail closed.
    it 'aborts (fails closed) rather than skipping the duplicate-key check' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/Could not verify .* for duplicate keys/).and_call_original

      expect do
        lint_placeholder_changes(old: '"greeting" = "Hello %@";', new: "\"k\" = { a = b; };\n")
      end.to raise_error(/Could not verify .* for duplicate keys/)
    end

    it 'proceeds (no abort) when the duplicate-key check is explicitly disabled' do
      expect(FastlaneCore::UI).not_to receive(:abort_with_message!)

      result = lint_placeholder_changes(
        old: '"greeting" = "Hello %@";',
        new: "\"k\" = { a = b; };\n",
        check_duplicate_keys: false
      )

      expect(result).to eq([])
    end
  end

  context 'with `InfoPlist.strings`-style unquoted keys and values' do
    # `CFBundleName = WordPress;` (key and value unquoted) is valid ASCII-plist; the scanner now
    # tokenizes it, so the action compares it like any other file instead of failing closed.
    it 'compares them without aborting' do
      expect(FastlaneCore::UI).not_to receive(:abort_with_message!)

      result = lint_placeholder_changes(
        old: "CFBundleName = WordPress;\n",
        new: "CFBundleName = Jetpack;\n"
      )

      expect(result).to eq([])
    end

    it 'still flags an incompatible placeholder change under an unquoted key' do
      # A value carrying a `%` placeholder is always quoted (a bare `%` isn't valid unquoted), so the
      # comparison runs on the quoted value while the key stays unquoted.
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/changed their format placeholders/)

      result = lint_placeholder_changes(
        old: 'NSHumanReadableCopyright = "Count: %d";',
        new: 'NSHumanReadableCopyright = "Count: %@";'
      )

      expect(result).to eq(
        [{ key: 'NSHumanReadableCopyright', old: 'Count: %d', new: 'Count: %@', old_signature: '1:int', new_signature: '1:object' }]
      )
    end
  end

  context 'when an input file cannot be parsed' do
    it 'fails with a clean error (not a raw plutil dump) for a malformed `.strings` file' do
      in_tmp_dir do |tmp_dir|
        old_file = File.join(tmp_dir, 'old.strings')
        new_file = File.join(tmp_dir, 'new.strings')
        File.write(old_file, '"key" = "value";')
        File.write(new_file, '"key" = "value"') # missing trailing semicolon — plutil rejects it

        expect do
          run_described_fastlane_action(old_file: old_file, new_file: new_file)
        end.to raise_error(/Could not parse `new\.strings`/)
      end
    end

    it 'fails with a clean error for a valid plist that is not a key/value dictionary' do
      in_tmp_dir do |tmp_dir|
        old_file = File.join(tmp_dir, 'old.strings')
        new_file = File.join(tmp_dir, 'new.strings')
        File.write(old_file, '"key" = "value";')
        File.write(new_file, '( "just", "an", "array" )') # valid plist, but an array, not a dictionary

        expect do
          run_described_fastlane_action(old_file: old_file, new_file: new_file)
        end.to raise_error(/not a valid `\.strings` file/)
      end
    end
  end

  context 'when a source value mixes positional and non-positional placeholders' do
    # Mixing `%1$@` and `%@` in one value is invalid (printf/`NSString` require all-or-nothing
    # positional), so its placeholder signature has no well-defined argument order and can't be
    # compared. The action always aborts — like duplicate keys, independently of `abort_on_violations`.
    it 'aborts, naming the offending key, instead of comparing an unreliable signature' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/mix positional.*and non-positional/).and_call_original

      expect do
        lint_placeholder_changes(old: '"greeting" = "Hello %@";', new: '"greeting" = "%1$@ says %d";')
      end.to raise_error(/mix positional.*and non-positional/)
    end

    it 'aborts even when `abort_on_violations` is false (the signature itself is unreliable)' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/mix positional.*and non-positional/).and_call_original

      expect do
        lint_placeholder_changes(old: '"k" = "%@";', new: '"k" = "%1$@ and %d";', abort_on_violations: false)
      end.to raise_error(/mix positional.*and non-positional/)
    end

    it 'detects a mix in the old file too' do
      expect(FastlaneCore::UI).to receive(:abort_with_message!).with(/mix positional.*and non-positional/).and_call_original

      expect do
        lint_placeholder_changes(old: '"k" = "%1$@ and %d";', new: '"k" = "%@";')
      end.to raise_error(/mix positional.*and non-positional/)
    end
  end
end
