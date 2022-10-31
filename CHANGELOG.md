# Release Toolkit CHANGELOG

---

## Trunk

### Breaking Changes

- Removed support for the deprecated `GHHELPER_ACCESS` in favor of `GITHUB_TOKEN` as the default environment variable to set the GitHub API token. [#420]
- The `github_client:` parameter (aka `ConfigItem`) is now mandatory for all Fastlane actions that use the GitHub API. [#420]
- The Fastlane action `comment_on_pr` has the parameter `access_key:` replaced by `github_token:`. [#420]

### New Features

_None_

### Bug Fixes

 - Improve resilience of the `ios_lint_localizations` action to support UTF16 files, and to warn and skip files in XML format when trying to detect duplicate keys on `.strings` files. [#418]
 - Work around GitHub API bug when creating a new milestone, where their interpretation of the milestone's due date sent during API call is incorrect when we cross DST change dates — leading to milestones created after Oct 30 having due dates set on Sunday instead of Monday. [#419]

### Internal Changes

_None_

## 5.6.0

### New Features

- Add `android_create_avd`, `android_launch_emulator` and `android_shutdown_emulator` actions. [#409]

### Internal Changes

- Require Fastlane `~> 2.210` to ensure Xcode 14 compatibility

## 5.5.0

### New Features

- Propose to retry when `gp_downloadmetadata` receives a `429 - Too Many Requests` error. [#406]

### Bug Fixes

- Update the URL used by `gp_downloadmetadata` to prevent consistent `301` responses. [#406]

### Internal Changes

- Remove call to `rake dependencies:pod:clean` from `ios_build_preflight` [#407]

## 5.4.0

### New Features

- Propose to retry when the download of GlotPress translations failed for a locale (especially useful for occurrences of `429 - Too Many Requests` quota limits) [#402]
- Add a `test_targets` parameter to the `android_firebase_test` action to be able to filter the tests to be run. [#403]

## 5.3.0

### New Features

- Add optional `release_notes_file_path` to `ios_update_release_notes` and `android_update_release_notes` [#396]
- Adds support for custom milestone duration [#397]

## 5.2.0

### New Features

- Add `tools:ignore="InconsistentArrays"` to `available_languages.xml` to avoid a linter warning on repos hosting multiple app flavors. [#390]
- Add the ability to provide a custom message for builds triggered via `buildkite_trigger_build` action [#392]

### Bug Fixes

* Fixes milestones being compared as strings instead of integers in `github_helper.get_last_milestone` [#391]

## 5.1.0

### New Features

* Allow using the `BUILDKITE_API_TOKEN` environment variable for the `buildkite_trigger_build` action. [#386]

### Bug Fixes

- Fix metadata length computation logic [[#383](https://github.com/wordpress-mobile/release-toolkit/pull/383)]

## 5.0.0

### Breaking Changes

* Update the version of Ruby required from `2.6.4` to `2.7.4`. [#377]

### New Features

* Introduce new `ios_send_app_size_metrics` and `android_send_app_size_metrics` actions. [#364] [#365]
* Add the ability to run Firebase Test Lab tests. [#355]

### Bug Fixes

_None_

### Internal Changes

_None_

## 4.2.0

### New Features

* The `ios_lint_localizations` action now also checks for duplicated keys in the `.strings` files.
  The behavior is optional via the `check_duplicate_keys` parameter and enabled by default. [#360]

### Bug Fixes

* Update GlotPress `export-translations` requests to avoid rate limiting. [#361] [#362]
* Fix bugs with the shell command in `promo_screenshots_helper`. [#366]

## 4.1.0

### New Features

* Add the option for `an_localize_libs` to provide a `source_id` for each library being merged.
  If provided, that identifier will be added as an `a8c-src-lib` XML attribute to the `<string>` nodes being updated with strings from said library.
  This can be useful to help identify where each string come from in the resulting, merged `strings.xml`. [#351]
* Add the option for `an_localize_libs` to set the `tools:ignore="UnusedResources"` XML attribute for each string being merged from a library. [#354]

### Bug Fixes

* Fix `ios_lint_localizations` action so that it no longer mistakely reports missing keys not yet translated in the other locales' `.strings` as violations. [#353]
* Fix `an_localize_libs` so that it does not move XML nodes around when merging lib strings (and replace them in-place instead). [#358]

### Internal Changes

* Updated the following internal dependencies: [#341]
	* nokogiri (1.12.5) -> (1.13.3)
	* oj (3.13.9) -> (3.13.11)
	* rake-compiler (1.1.1) -> (1.1.9)
* Updated the following public dependency: [#341]
	* buildkit (1.4.5) -> (1.5.0)

## 4.0.0

### Breaking Changes

* Update the API of `ios_merge_strings_files` and `ios_extract_keys_from_strings_files` to support using prefixes for string keys when merging/splitting the files.
  The actions now expect a `Hash` (instead of an `Array`) for the list of files to provide an associated prefix (or `nil` or `''` when none) for each file to merge/split. [#345]

### Bug Fixes

* Improved logs and console output, to avoid `ios_download_strings_files_from_glotpress` to look like it's deadlocked while it takes some time to download all the exports of all the locales, and to avoid the log messages from `ios_extract_keys_from_strings_files` to be misleading. [#344]

## 3.1.0

### New Features

* Introduce new `ios_extract_keys_from_strings_files` action. [#338]
* Add Upload to S3 Action. [#339]

## 3.0.0

### Breaking Changes

* Removes the `drawText` binary from the gem (instead depending on it being installed via `brew`). Because this update can not be safely applied with no side effects, it's considered a breaking change. [#312]
* When doing Git operations, if no branch is provided, we'll use `trunk` as a default instead of `develop` [#335]
* Remove deprecated `android_merge_translators_strings`, `android_update_metadata`, and `ios_merge_translators_strings` actions [#337]

### New Features

* Introduce new `ios_merge_strings_files` action. [#329]
* Introduce new `buildkite_trigger_build` action. [#333]
* Introduce new `ios_download_strings_files_from_glotpress` action. [#331]

### Internal Changes

* Ensure that the `gem push` step only runs on CI if lint, test and danger steps passed before it. [#325]
* Rename internal `Ios::L10nHelper` to `Ios::L10nLinterHelper`. [#328]
* Provide new `run_described_fastlane_action` to run Fastlane actions more thoroughly in unit tests [#330]

## 2.3.0

### New Features

* Added parameter for default/base branch across several actions [#319]

## 2.2.0

### New Features

* Added a new `ios_generate_strings_file_from_code` action to replace the now-deprecated `ios_localize_project` action (and `Scripts/localize.py` script in app repos). [#309, #311]
* Added a `comment_on_pr` action to allow commenting on (and updating comments on) PRs. [#313]
* Added the ability to use the `GITHUB_TOKEN` environment variable for GitHub operations. `GHHELPER_ACCESS` will be deprecated in a future version. [#313]
* Added support for downloading GitHub content for private repositories [#321]

### Bug Fixes

* Fixed the rendering of PR links in the body of GitHub Releases created via the `create_release` action. [#316]
* Fixed a bug introduced in [#313] that caused the GitHub helper not to work [#318]

## 2.1.0

### New Features

* Added a reminder mechanism for when you forgot a prompt was waiting for you in the Terminal. This reminder is [configurable via environment variables](https://github.com/wordpress-mobile/release-toolkit/blob/5c9b79db4bfcb298376fe3e81bc53881795922a5/lib/fastlane/plugin/wpmreleasetoolkit/helper/interactive_prompt_reminder.rb#L3-L22) to change the default delays and optionally opt-in for speaking a voice message in addition to the default beep + dock icon badge. [#302]

### Internal Changes

- Replace CircleCI and GitHub Actions with Buildkite

## 2.0.0

### Breaking Changes

* Updates the keys used for version reads and bumps when using a `version.properties` file in Android. [#298]
* Removed the `app:` parameter (aka `ConfigItem`) from all the Android version-related actions, now that versions are unified for all apps. [#300]

### Bug Fixes

* Strip trailing new lines in single line msgid when generating .po[t] file. [#297]

## 1.4.0

### New Features

* Add option to skip updating `Deliverfile` when creating a new hotfix version (`ios_bump_version_hotfix`) [#287]

### Bug Fixes

* Fixes a bug that was breaking the `promo_screenshots` helper [#276]
* Fix crashes in actions dealing with hotfixes. [#288]

### Internal Changes

* Opt-out from installing platform-specific gems with Bundler [#293]
* Update gems in the repository to fix `addressable` security vulnerability [#294]

## 1.3.1

### Bug Fixes

* Fix crashes introduced in `1.3.0` – incorrect parameters in calls to `get_release_version`. [#283]
* Fix the way versioning is handled for alphas – i.e. `version.properties` is indexed by flavor name, defaulting to `zalpha` for alphas. [#283]
* Fixed an issue in `check_translation_progress` where a wrong evaluation of the progress is possible when there are Waiting string in GlotPress.

## 1.3.0

### New Features

* Support for a `version.properties` to manage app versioning - all existing paths remain intact and new paths are only used when a `version.properties` file is present.
* Add support for providing an `app:` parameter to most versioning-related actions to allow support for multiple apps hosted in a monorepo.
* Supporting the new `version.properties` file also allows for the `HAS_ALPHA_VERSION` variable to be removed as the alpha reference in the properties file will be used going forward.
* Clients adopting the new `version.properties` will need to implement a gradle task named `updateVersionProperties` to update the `version.properties` file.

### Internal Changes

* Some cleanup to how we scope variables in some of our actions

## 1.2.0

### New Features

* Added a `check_translation_progress` action which checks the status of the translations on GlotPress. [#263]

## 1.1.0

### New Features

* New `check_for_toolkit_updates` action, to ensure you are always using the latest version of the release-toolkit plugin. [#269]
* `android_download_translations` action now also auto-substitute hyphens for en-dash when appropriate, to avoid Android Linter violations. [#268]

### Internal Changes

* Updated our rubocop config and fixed some more new/existing violations. [#270]

## 1.0.1

### Internal Changes

* Updated the `gemspec`'s `bundler` and `rubocop` dependencies to fix a publishing warning. [#261]
* Fixed an issue with the `gemspec`'s definition of the `drawText` extension – which prevented the native extension from being built when referencing the toolkit via a version number rather than a tag in your `Gemfile`. [#262]

## 1.0.0

This is our first official release.
