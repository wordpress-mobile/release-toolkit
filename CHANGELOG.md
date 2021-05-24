# Release Toolkit CHANGELOG

---

## Develop

### Breaking Changes

_None_

### New Features

* Added a `check_translation_progress` action which checks the status of the translations on GlotPress. [#263]

### Bug Fixes

_None_

### Internal Changes

* Updated the `gemspec`'s `bundler` and `rubocop` dependencies to fix a publishing warning. [#261]
* Fixed an issue with the `gemspec`'s definition of the `drawText` extension – which prevented the native extension from being built when referencing the toolkit via a version number rather than a tag in your `Gemfile`. [#262]

## 1.0.0

This is our first official release.
