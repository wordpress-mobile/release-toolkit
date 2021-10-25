# Release Toolkit CHANGELOG

---

## Develop

### Breaking Changes

_None_

### New Features

_None_

### Bug Fixes

_None_

### Internal Changes

_None_

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
