# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Helper::Ios::L10nLinterHelper do
  describe '.only_omits_placeholders?' do
    def only_omits?(base, translation)
      described_class.only_omits_placeholders?(base: base, translation: translation)
    end

    it 'accepts dropping the only placeholder' do
      expect(only_omits?('%1$ld word', 'Un cuvânt')).to be true
    end

    it 'accepts dropping a trailing positional placeholder' do
      expect(only_omits?('Post %1$@ has %2$@ like.', 'Postarea %1$@ are o apreciere.')).to be true
    end

    it 'accepts dropping several trailing positional placeholders' do
      expect(only_omits?('%1$@, %2$d, %3$@', '%1$@ doar')).to be true
    end

    it 'rejects dropping a leading positional placeholder, as Foundation would format the first argument in its place' do
      expect(only_omits?('Post %1$@ has %2$@ likes.', 'O postare are %2$@ aprecieri.')).to be false
    end

    it 'rejects dropping a middle positional placeholder, as Foundation would shift the arguments after it' do
      expect(only_omits?('%1$@, %2$d, %3$@', '%1$@, %3$@')).to be false
    end

    it 'accepts dropping a trailing sequential placeholder' do
      expect(only_omits?('%@ and %d', 'doar %@')).to be true
    end

    it 'rejects dropping a leading sequential placeholder, as it shifts the remaining arguments' do
      expect(only_omits?('%@ and %d', 'doar %d')).to be false
    end

    it 'treats length modifiers that read the same size of integer as the same type' do
      expect(only_omits?('%1$ld of %2$ld', '%1$lld')).to be true
      expect(only_omits?('%1$ld of %2$ld', '%1$zd')).to be true
      expect(only_omits?('%1$ld of %2$ld', '%1$D')).to be true
      expect(only_omits?('%1$d of %2$d', '%1$i')).to be true
    end

    it 'rejects a length modifier that reads a different size of integer, as it would truncate the value' do
      expect(only_omits?('%1$ld of %2$ld', '%1$d')).to be false
      expect(only_omits?('%1$ld of %2$ld', '%1$hhd')).to be false
      expect(only_omits?('%1$d of %2$d', '%1$hd')).to be false
    end

    it 'rejects a different conversion of the same kind of argument' do
      expect(only_omits?('%1$ld of %2$ld', '%1$lu')).to be false
      expect(only_omits?('%1$f of %2$f', '%1$Lf')).to be false
      expect(only_omits?('%1$C and %2$C', '%1$c')).to be false
    end

    it 'ignores length modifiers that do not change the argument read' do
      expect(only_omits?('%1$f of %2$f', '%1$lf')).to be true
      expect(only_omits?('%1$C and %2$C', '%1$lc')).to be true
    end

    it 'ignores escaped percent signs' do
      expect(only_omits?('%1$d%% of %2$d', '%1$d%%')).to be true
    end

    it 'rejects a placeholder whose type differs from the base' do
      expect(only_omits?('%1$d of %2$@', '%1$@')).to be false
    end

    it 'rejects a placeholder at a position missing from the base' do
      expect(only_omits?('%1$d of %2$@', '%3$@')).to be false
    end

    it 'rejects a translation with as many placeholders as the base' do
      expect(only_omits?('%1$d items', '%1$d elemente')).to be false
    end

    it 'rejects a blank translation' do
      expect(only_omits?('%1$@ of %2$@ used', '')).to be false
      expect(only_omits?('%1$@ of %2$@ used', ' ')).to be false
    end

    it 'rejects an incomplete placeholder' do
      expect(only_omits?('%1$ld words', '%1$l 个字')).to be false
    end

    it 'rejects a `*` width, as it consumes an extra argument' do
      expect(only_omits?('%1$d and %2$d', '%*d')).to be false
    end

    it 'rejects mixing positional and sequential placeholders' do
      expect(only_omits?('%1$@ %2$d %3$@', '%1$@ %d')).to be false
    end

    it 'rejects reusing a position with a different type' do
      expect(only_omits?('%1$d %2$@ %3$@', '%1$d %1$@')).to be false
    end
  end
end
