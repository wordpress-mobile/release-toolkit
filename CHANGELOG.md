# Release Toolkit CHANGELOG

---

## Trunk

### Breaking Changes

- Removed `build_gradle_path` parameter from `android_current_branch_is_hotfix` [#579]
- Deleted `Fastlane::Helper::Android::GitHelper` and `Fastlane::Helper::Ios::GitHelper` [#579]
- Deleted the following deprecated actions: [#577, #579, #586]
    - `android_betabuild_prechecks`
    - `android_build_prechecks`
    - `android_bump_version_beta`
    - `android_bump_version_final_release`
    - `android_bump_version_hotfix`
    - `android_bump_version_release`
    - `android_codefreeze_prechecks`
    - `android_completecodefreeze_prechecks`
    - `android_finalize_prechecks`
    - `android_get_alpha_version`
    - `android_get_app_version`
    - `android_get_release_version`
    - `android_hotfix_prechecks`
    - `android_tag_build`
    - `ios_betabuild_prechecks`
    - `ios_build_prechecks`
    - `ios_bump_version_beta`
    - `ios_bump_version_hotfix`
    - `ios_bump_version_release`
    - `ios_codefreeze_prechecks`
    - `ios_completecodefreeze_prechecks`
    - `ios_current_branch_is_hotfix`
    - `ios_finalize_prechecks`
    - `ios_get_app_version`
    - `ios_get_build_number`
    - `ios_get_build_version`
    - `ios_hotfix_prechecks`
    - `ios_tag_build`
    - `ios_validate_ci_build`

### New Features

_None_

### Bug Fixes

_None_

### Internal Changes

- Updated our internal Ruby dependencies. [#582]

## 11.1.0

### New Features

- Added the action `create_release_backmerge_pull_request` to facilitate the creation of Pull Requests merging a release branch back to the main branch or currently ongoing releases [#570]

## 11.0.3

### Bug Fixes

- Fix `android_download_translation` issues reported in #569 [#571]
   - add post-processing of `plurals` nodes too.
   - detect and fix `\@string/` references escaped in GlotPress exports.
   - replicate all XML attributes (and xmlns) present in `values/string.xml` on the corresponding nodes in the translated XML.

## 11.0.2

### New Features

- `buildkite_trigger_build` now returns the web URL of the Buildkite build it scheduled [#564]

### Internal Changes

- Bump `yard` from `0.9.34` to `0.9.36` [#554]
- Bump `nokogiri` from `1.16.2` to `1.16.5` [#566]
- Bump `rexml` from `3.2.6` to `3.2.8` [#566]

## 11.0.1

### Bug Fixes

- Fixed the `android_download_translations` action by correctly calling Fastlane's `git_submodule_update` action [#561]

## 11.0.0

### Breaking Changes

- Make `ios_check_beta_deps` use the `Podfile.lock` instead of `Podfile` for its detection, and also be able to detect Pods referenced by commits and branches.
  If your `Fastfile` called this action with an explicit `podfile: …` argument, you'll have to update the call to use `lockfile:` instead (or rely on defaults). [#557]

## 10.0.0

### Breaking Changes

- Upgraded the minimum required Ruby version to `3.2.2`. [#517]
- Removed the old `setbranchprotection` and `removebranchprotection` backwards-compatiblity stubs for the now-renamed `set_branch_protection` and `remove_branch_protection` actions. [#549]
- Renamed `setfrozentag` action to `set_milestone_frozen_marker`. [#548]
- Removed the `ios_clear_intermediate_tags` action, which has been deprecated for a while. [#549]
- Removed the `has_alpha_version` option from several actions and helper methods. It has already been deprecated for many versions. [#550]
- Removed the `project_name` and `project_root_folder` options from several actions. [#550]
- Renamed `update_pull_requests_milestone` to `update_assigned_milestone` and make it handle GitHub issues as well as PRs. [#547]

### Bug Fixes

- Fixed `comment_on_pr` to allow first paragraph of the comment to still be interpreted as Markdown. [#544]

### Internal Changes

- Added a deprecation notice to the `GitHelper.ensure_on_branch!` method [#531]
- Added a deprecation notice to the `GitHelper.update_submodules` method [#531]
- Update `nokogiri`, `mini_portile2`, and `rmagick` [#546]

## 9.4.0

### New Features

- Added `update_pull_requests_milestone` action, to move all still-opened PRs of a given milestone to another milestone. [#539]

### Internal Changes

- Moves the mac-based parts of CI over to Apple Silicon. [#541]

## 9.3.1

### Bug Fixes

- Updated QRCode generated images (for Prototype Build) to use https://goqr.me/api as a replacement to the now-discontinued Google service. [#537]

## 9.3.0

### New Features

- Added optional `has_alpha_version` config item to actions that previously used the `HAS_ALPHA_VERSION` environment variable [#522]
- Added a versioning method to check if a release is a hotfix [#530]

### Internal Changes

- Added deprecation notices to any actions or methods using the `HAS_ALPHA_VERSION` environment variable [#522]
- Use SwiftGen 6.6.2 to address an Apple Silicon CI issue [#534]

## 9.2.0

### New Features

- Added optional `build_gradle_path` and `version_properties_path` config items to actions that previously used the `PROJECT_ROOT_FOLDER` environment variable [#519]

### Internal Changes

- Added deprecation notices to any actions or methods using the `PROJECT_ROOT_FOLDER` environment variable [#519]
- Added deprecation notices to any actions or methods using the `PROJECT_NAME` environment variable [#519]

## 9.1.0

### New Features

- Adds `AppVersion` and `BuildCode` models that can be used by version actions. [#512]
- Adds calculator and formatter classes that can be used with the `AppVersion` and `BuildCode` models. [#512]
- Renamed `addbranchprotection` to `set_branch_protection`, and allow it to provide additional optional protection
   settings to set/update on the target branch (like `lock_branch`, `required_ci_checks`, etc).
   The `addbranchprotection` action name still exists for backward compatibility for now (with a deprecation notice),
   but it will be removed in a future major release. [#513]
- Renamed `removebranchprotection` to `remove_branch_protection`.
   The `removebranchprotection` action name still exists for now for backward compatibility (with a deprecation notice),
   but it will be removed in a future major release. [#513]
- Added `copy_branch_protection` action to replicate the branch protection settings of one branch onto another. [#513]

## 9.0.1

### Bug Fixes

- Fix metadata `po` generation for iOS projects removing the final `\n`. [#498]

## 9.0.0

### Breaking Changes

_See the [`MIGRATION.md`](MIGRATION.md) file for more detailed instructions and options to handle those breaking changes._

- Add the `public_version_xcconfig_file` parameter to the `ios_get_app_version` action to replace the need for an environment variable. [#445]
- Remove the `ios_localize_project` and `ios_update_metadata` actions. [#447]
- Remove the `skip_deliver` parameter from `ios_bump_version_hotfix` and `ios_bump_version_release` actions. [#450]
- Remove the `get_prs_list` action, as its was obsolete (and not used by any client project anymore). [#505]

### New Features

- Adds `if_exists` parameter to `upload_to_s3` action, with possible values `:skip`, `:fail`, and `:replace`. [#495]
- The `create_release` action now prints and returns the URL of the created GitHub Release. [#503]
- Removes `bigdecimal` dependency. [#504] [#507]
- Supports Ruby 3. [#492, #493, #497, and #504]
- Add `find_previous_tag` and `get_prs_between_tags` actions. [#505]

### Bug Fixes

- Prevent using non-integer `version_code` values for Android hotfixes [#167]

### Internal Changes

- Updates `octokit` to `6.1.1`, `danger` to `9.3.1` and `buildkite-test_collector` to `2.3.1`. [#491]
- Fix issue with gems cache on CI when testing against Ruby `3.2.2`. [#506]

## 8.1.0

### New Features

- Adds auto_retry option to `gp_downloadmetadata_action`. [#474]

## 8.0.1

### Bug Fixes

- Revert the `gp_downloadmetadata_action` `locales` item type from `type: Hash` to `is_string: false`. [#478]

## 8.0.0

### Breaking Changes

- Remove git push commands after creating a new commit or branch. [#472] See `MIGRATION.md` for instructions.

## 7.1.2

### Bug Fixes

- Revert the `gp_downloadmetadata_action` `locales` item type from `type: Hash` to `is_string: false`. [#480]

## 7.1.1

### Internal Changes

- Remove `rubygems_mfa_required` from the `gemspec`. [#475]

## 7.1.0

### New Features

- Add `ios_get_build_number` action to get the current build number from an `xcconfig` file. [#458]


### Internal Changes

- Add "Mobile Secrets" to `configure_update` current branch message to clarify which repo it's referring to. [#455]
- `buildkite_trigger_build` now prints the web URL of the newly scheduled build, to allow you to easily open it via cmd-click. [#460]
- Add the branch information to the 'This is not a release branch' error that's thrown from complete code freeze lane. [#461]
- Update `octokit` to `5.6.1` This is a major version bump from version `4.18`, but is not a breaking change for the Release Toolkit because it doesn't change any public APIs for clients. [#464]
- Update `danger` to `9.3.0`. This is an internal-only change and is not a breaking change for clients. [#464]
- Replace `rspec-buildkite-analytics` with `buildkite-test_collector` (Buildkite renamed the gem) and update it to `2.2.0`. This is another internal-only change and is not a breaking change for clients. [#465]
- Adds `ignore_pipeline_branch_filters=true` parameter to the API call triggering a Buildkite build [#468]
- Replace all instances of `is_string` with `type` [#469]
- Use `git_branch_name_using_HEAD` instead of `git_branch` so that the return value is not modified by environment variables. This has no impact to our current release flow, that's why it's not in "Breaking changes" section. [#463]
- Deprecate `ios_clear_intermediate_tags` & `ios_final_tag` actions. [#471]

## 7.0.0

### Breaking Changes

- Remove the `skip_glotpress` parameter from the `ios_bump_version_release` action [#443]

### New Features

- Add new `buildkite_annotate` action to add/remove annotations from the current build. [#442]
- Add new `buildkite_metadata` action to set/get metadata from the current build. [#442]
- Add new `prototype_build_details_comment` action to make it easier to generate the HTML comment about Prototype Builds in PRs. [#449]

### Internal Changes

- Updates `activesupport` to `6.1.7.1`, addressing [a security issue](https://github.com/advisories/GHSA-j6gc-792m-qgm2). This is a major version change, but as the dependency is internal-only, it shouldn't be a breaking change for clients. [#441]
- Add the explicit dependency to `xcodeproj (~> 1.22)`, used in this case to replace the previous manual parsing of `.xcconfig` files. [#451]

## 6.3.0

### New Features

- Add Mac support to all `common` actions and any relevant `ios` actions [#439]

## 6.2.0

### New Features

- Add a `is_draft` parameter to the `create_release` action to specify whether the release should be created as a draft. [#433]

### Internal Changes

- Update the CI image used to build this project to use `xcode-14.1`. [#431]

## 6.1.0

### New Features

- Allow `android_firebase_test` to not crash on failure, letting the caller do custom failure handling (e.g. Buildkite Annotations, etc) on their side. [#430]
- `promo_screenshots` now checks that the fonts—referenced via `font-family` in all the stylesheets referenced in the config file—are installed before starting, and prompt to install them if they are not. This check is enabled by default now but can be disabled/skipped if it causes any issue. [#429]
- `promo_screenshots` now supports config files to be written in `YAML` in addition to still supporting `JSON`. [#429]

### Bug Fixes

- Fix deprecation warning in `RMagick` call used by `promo_screenshots` action. [#429]

## 6.0.0

### Breaking Changes

- Removed support for the deprecated `GHHELPER_ACCESS` in favor of `GITHUB_TOKEN` as the default environment variable to set the GitHub API token. [#420]
- The `github_token:` parameter (aka `ConfigItem`)–or using the corresponding `GITHUB_TOKEN` env var to provide it a value–is now mandatory for all Fastlane actions that use the GitHub API. [#420]
- The Fastlane action `comment_on_pr` has the parameter `access_key:` replaced by `github_token:`. [#420]

### New Features

- Allow `upload_to_s3` action to just log instead of crash (using new `skip_if_exists` parameter) when the file already exists in the S3 bucket. [#427]

### Bug Fixes

 - Improve resilience of the `ios_lint_localizations` action to support UTF16 files, and to warn and skip files in XML format when trying to detect duplicate keys on `.strings` files. [#418]
 - Work around GitHub API bug when creating a new milestone, where their interpretation of the milestone's due date sent during API call is incorrect when we cross DST change dates — leading to milestones created after Oct 30 having due dates set on Sunday instead of Monday. [#419]

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
