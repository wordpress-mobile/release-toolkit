require_relative './spec_helper'

describe Fastlane::Helper::AndroidLocalizeHelper do
  it 'get_glotpress_languages_translated_morethan90 finds all languages at completion threshold' do
    languages_at_threshold = ["es-ve", "ru", "ko", "zh-cn"]
    test_text = %q(
        <strong><a href="/projects/apps/android/dev/es-ve/default/">Spanish (Venezuela)</a></strong>
                <span class="bubble morethan90">100%</span>
        <strong><a href="/projects/apps/android/dev/ru/default/">Russian</a></strong>
                <span class="bubble morethan90">100%</span>
        <strong><a href="/projects/apps/android/dev/ko/default/">Korean</a></strong>
                <span class="bubble morethan90">96%</span>
        <strong><a href="/projects/apps/android/dev/zh-cn/default/">Chinese (China)</a></strong>
                <span class="bubble morethan90">91%</span>
    )

    languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text);

    # verify function return value
    expect(languages_at_threshold.sort).to eq languages_found.sort
  end

  it 'get_glotpress_languages_translated_morethan90 finds only languages at completion threshold' do
    languages_at_threshold = ["es-ve", "ru"]
    test_text = %q(
        <strong><a href="/projects/apps/android/dev/es-ve/default/">Spanish (Venezuela)</a></strong>
                <span class="bubble morethan90">100%</span>
        <strong><a href="/projects/apps/android/dev/ru/default/">Russian</a></strong>
                <span class="bubble morethan90">100%</span>
        <strong><a href="/projects/apps/android/dev/zh-hk/default/">Chinese (Hong Kong)</a></strong>
        <strong><a href="/projects/apps/android/dev/cs/default/">Czech</a></strong>
    )

    languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text);

    # verify function return value
    expect(languages_at_threshold.sort).to eq languages_found.sort
  end

  it 'get_glotpress_languages_translated_morethan90 finds no languages when none is at threshold' do
    test_text = %q(
        <strong><a href="/projects/apps/android/dev/zh-hk/default/">Chinese (Hong Kong)</a></strong>
        <strong><a href="/projects/apps/android/dev/cs/default/">Czech</a></strong>
        <strong><a href="/projects/apps/android/dev/ms/default/">Malay</a></strong>
        <strong><a href="/projects/apps/android/dev/el/default/">Greek</a></strong>
    )

    languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text);

    # verify function return value
    expect(languages_found.empty?).to be true
  end

  it 'get_glotpress_languages_translated_morethan90 result empty when input is irrelevant html' do
    test_text = %q(
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" dir="ltr" lang="en-US">
        <head profile="http://gmpg.org/xfn/11">
        <meta charset="utf-8" />
        <!--
        <meta property="fb:page_id" content="6427302910" />
        -->
        <nav aria-label="Main Menu">
        <ul id="wporg-header-menu">
        <li class="menu-item"><a href='//wordpress.org/showcase/' data-title='See some of the sites built on WordPress.'>Showcase</a></li>
        <td class="stats translated" title="translated">
            <a href="/projects/apps/android/dev/el/default/?filters%5Btranslated%5D=yes&#038;filters%5Bstatus%5D=current">1270</a>              </td>
        <td class="stats percent">47%</td>
    )
    languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text);

    # verify function return value
    expect(languages_found.empty?).to be true
  end

  it 'get_glotpress_languages_translated_morethan90 result empty when input is random text' do
    test_text = %q(
        !#$%&' ()*+,- ./{|}~[\]^_`: ;<=>?Ⓟ @︼︽︾⑳₡
        ¢£¤¥¦§¨©ª«¬®¯ °±²ɇɈɉɊɋɌɎɏɐɑɒɓɔ ɕɖɗɘəɚ⤚▓⤜⤝⤞⤟ⰙⰚⰛⰜ⭑⬤⭒‰ ꕢ ꕣꕤ ꕥ￥￦
        ❌ ⛱⛲⛳⛰⛴⛵ ⚡⏰⏱⏲⭐ ✋☕⛩⛺⛪✨ ⚽ ⛄⏳
        ḛḜḝḞṶṷṸẂ ẃ ẄẅẆ ᾃᾄᾅ ᾆ Ṥṥ  ȊȋȌ ȍ Ȏȏ ȐṦṧåæçèéêë ì í ΔƟΘ
        㥯㥰㥱㥲㥳㥴㥵 㥶㥷㥸㥹㥺 俋 俌 俍 俎 俏 俐 俑 俒 俓㞢㞣㞤㞥㞦㞧㞨쨜 쨝쨠쨦걵걷 걸걹걺ﾓﾔﾕ ﾖﾗﾘﾙ
        ﵑﵓﵔ ﵕﵗ ﵘ  ﯿ ﰀﰁﰂ ﰃ ﮁﮂﮃﮄﮅᎹᏪ Ⴥჭᡴᠦᡀ
    )
    languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text);

    # verify function return value
    expect(languages_found.empty?).to be true
  end

  it 'get_glotpress_languages_translated_morethan90 result empty when input is empty string' do
    test_text = ""
    languages_found = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90(test_text);

    # verify function return value
    expect(languages_found.empty?).to be true
  end

end
