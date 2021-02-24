require_relative '../../../spec_helper'

describe ReleaseToolkit::Models::Android::VersionName do
  context 'when creating a new instance' do
    context 'with an alpha version' do
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
    end

    context 'with a non-hotfix beta version' do
      let(:version) { described_class.new_beta(major: 1, minor: 2, beta: 42) }

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
    end

    context 'with a hotfix beta version' do
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
    end

    context 'with a non-hotfix final version' do
      let(:version) { described_class.new_final(major: 1, minor: 2) }

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
    end

    context 'with a hotfix final version' do
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
    end

    context 'with a string' do
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
end
