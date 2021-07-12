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

Update the `BigDecimal` and `ActiveSupport` gems to clean up our `Gemfile` and improve future compatibility.

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
