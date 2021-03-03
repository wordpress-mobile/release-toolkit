require_relative '../../../spec_helper'

describe ReleaseToolkit::Models::Android::VersionName do
  context 'when using an alpha version' do
    let(:version) { described_class.new_alpha(number: 42) }

    it 'is identified as alpha' do
      expect(version.is_alpha?).to be(true)
      expect(version.is_beta?).to be(false)
      expect(version.is_final?).to be(false)
      expect(version.is_hotfix?).to be(false)
    end

    it 'has the proper values' do
      expect(version.major).to be_nil
      expect(version.minor).to be_nil
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to eq(42)
    end

    it 'has the proper string representation' do
      expect(version.to_s).to eq('alpha-42')
    end

    it 'raises when trying to convert into a final version' do
      expect { version.to_final }.to raise_error(RuntimeError)
    end
  end

  shared_examples 'non-hotfix-beta' do
    it 'is identified as non-hotfix beta' do
      expect(version.is_alpha?).to be(false)
      expect(version.is_beta?).to be(true)
      expect(version.is_final?).to be(false)
      expect(version.is_hotfix?).to be(false)
    end

    it 'has the proper values' do
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to eq(42)
    end

    it 'has the proper string representation' do
      expect(version.to_s).to eq('1.2-rc-42')
    end

    it 'has the proper string representation even with hotfix value of 0' do
      expect(version.to_s).to eq('1.2-rc-42')
    end

    it 'properly converts into a final version' do
      final = version.to_final
      expect(final.is_final?).to be(true)
      expect(final.major).to eq(1)
      expect(final.minor).to eq(2)
      expect(final.hotfix).to be_nil
      expect(final.prerelease_num).to be_nil
    end
  end

  context 'when using a non-hotfix beta version' do
    let(:version) { described_class.new_beta(major: 1, minor: 2, beta: 42) }

    include_examples('non-hotfix-beta')
  end

  context 'when using a zero-hotfix beta version' do
    let(:version) { described_class.new_beta(major: 1, minor: 2, hotfix: 0, beta: 42) }

    include_examples('non-hotfix-beta')
  end

  context 'when using a hotfix beta version' do
    let(:version) { described_class.new_beta(major: 1, minor: 2, hotfix: 3, beta: 42) }

    it 'is identified as hotfix beta' do
      expect(version.is_alpha?).to be(false)
      expect(version.is_beta?).to be(true)
      expect(version.is_final?).to be(false)
      expect(version.is_hotfix?).to be(true)
    end

    it 'has the proper values' do
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to eq(3)
      expect(version.prerelease_num).to eq(42)
    end

    it 'has the proper string representation' do
      expect(version.to_s).to eq('1.2.3-rc-42')
    end

    it 'properly converts into a final version' do
      final = version.to_final
      expect(final.is_final?).to be(true)
      expect(final.major).to eq(1)
      expect(final.minor).to eq(2)
      expect(final.hotfix).to eq(3)
      expect(final.prerelease_num).to be_nil
    end
  end

  shared_examples('non-hotfix-final') do
    it 'is identified as non-hotfix final' do
      expect(version.is_alpha?).to be(false)
      expect(version.is_beta?).to be(false)
      expect(version.is_final?).to be(true)
      expect(version.is_hotfix?).to be(false)
    end

    it 'has the proper values' do
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to be_nil
    end

    it 'has the proper string representation' do
      expect(version.to_s).to eq('1.2')
    end

    it 'does not change when converting to final version' do
      expect(version.to_final).to eq(version)
    end
  end

  context 'when using a non-hotfix final version' do
    let(:version) { described_class.new_final(major: 1, minor: 2) }

    include_examples('non-hotfix-final')
  end

  context 'when using a zero-hotfix final version' do
    let(:version) { described_class.new_final(major: 1, minor: 2, hotfix: 0) }

    include_examples('non-hotfix-final')
  end

  context 'when using a hotfix final version' do
    let(:version) { described_class.new_final(major: 1, minor: 2, hotfix: 3) }

    it 'is identified as hotfix final' do
      expect(version.is_alpha?).to be(false)
      expect(version.is_beta?).to be(false)
      expect(version.is_final?).to be(true)
      expect(version.is_hotfix?).to be(true)
    end

    it 'has the proper values' do
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to eq(3)
      expect(version.prerelease_num).to be_nil
    end

    it 'has the proper string representation' do
      expect(version.to_s).to eq('1.2.3')
    end

    it 'does not change when converting to final version' do
      expect(version.to_final).to eq(version)
    end
  end

  context 'when creating an instance from a string' do
    it 'parses an alpha correctly' do
      version = described_class.from_string('alpha-42')
      expect(version.is_alpha?).to be(true)
      expect(version.major).to be_nil
      expect(version.minor).to be_nil
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to eq(42)
    end

    it 'parses a non-hotfix beta correctly' do
      version = described_class.from_string('1.2-rc-42')
      expect(version.is_beta?).to be(true)
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to eq(42)
    end

    it 'parses a zero-hotfix beta correctly' do
      version = described_class.from_string('1.2.0-rc-42')
      expect(version.is_beta?).to be(true)
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to eq(42)
    end

    it 'parses a hotfix beta correctly' do
      version = described_class.from_string('1.2.3-rc-42')
      expect(version.is_beta?).to be(true)
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to eq(3)
      expect(version.prerelease_num).to eq(42)
    end

    it 'parses a non-hotfix final correctly' do
      version = described_class.from_string('1.2')
      expect(version.is_final?).to be(true)
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to be_nil
    end

    it 'parses a zero-hotfix final correctly' do
      version = described_class.from_string('1.2.0')
      expect(version.is_final?).to be(true)
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to be_nil
      expect(version.prerelease_num).to be_nil
    end

    it 'parses a hotfix final correctly' do
      version = described_class.from_string('1.2.3')
      expect(version.is_final?).to be(true)
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.hotfix).to eq(3)
      expect(version.prerelease_num).to be_nil
    end

    it 'raises on invalid format' do
      expect { described_class.from_string('1.2.x') }.to raise_error(ArgumentError)
      expect { described_class.from_string('1.2-3') }.to raise_error(RuntimeError)
      expect { described_class.from_string('1.2-beta-3') }.to raise_error(RuntimeError)
      expect { described_class.from_string('-42')}.to raise_error(RuntimeError)
    end
  end
end
