# Migration Instructions for Major Releases

## From 11.x to 12.0.0

- `android_current_branch_is_hotfix` no longer supports the `build_gradle_path` parameter. Convert the project to define `versionName` and `versionCode` in `version.properties` and call `android_current_branch_is_hotfix` with `version_properties_path`.
- Various helper methods and actions to calculate version bumps have been deleted (see `CHANGELOG.md` for the full list). Use the `Versioning` module for any version computation or automation.
- `Fastlane::Helper:Android::GitHelper` and `Fastlane::Helper::Ios::GitHelper` have been removed. If you were using their respective `commit_version_bump` methods, you'll need to run the commit directly in your `Fastfile`, for example via Fastlane's `git_commit` action.
- `android_tag_build` and `ios_tag_build` have been removed. Our recommended workflow for tagging releases relies on GitHub creating a tag when a GitHub release is published.
- `create_release` has been removed. Use `create_github_release` instead.

## From `10.0.0` to `11.0.0`

- The `ios_check_beta_deps` now uses the `Podfile.lock` instead of `Podfile` for its detection. If you called this action with an explicit `podfile: …` argument, you'll have to update the call to use `lockfile:` instead—or remove that argument completely from your call and rely on its default value being `Podfile.lock`.

## From `9.0.0` to `10.0.0`

 - The new minimum required Ruby version is `3.2.2`. Please make sure to upgrade your projects before upgrading to this version to avoid compatibility issues.
 - Action `setbranchprotection` has been renamed `set_branch_protection`. Besides, you might want to use the new `copy_branch_protection(from_branch: to_branch:)` instead (especially for protecting the `release/*` branch with the same settings as `trunk` after a code-freeze).
 - Action `removebranchprotection` has been renamed `remove_branch_protection`.
 - Action `setfrozentag` has been renamed `set_milestone_frozen_marker`.
 - Actions `ios_clear_intermediate_tags` and `ios_final_tag` have been removed, as they have been deprecated for a while.
 - Option `has_alpha_version` has been removed after being deprecated for a while.
 - Options `project_name` and `project_root_folder` have been removed from several actions. Explicit paths should be passed instead.
 - Action `update_pull_requests_milestone` has been renamed `update_assigned_milestone` and its `pr_numbers` and `pr_comment` parameters renamed to just `numbers` and `comment`; the action now acts on Issues and not just PRs anymore.

## From `8.0.0` to `9.0.0`

- The deprecated actions `ios_localize_project` and `ios_update_metadata` were now completely removed. If your project is still using them, please use the new tooling instead.
  - See `ios_generate_strings_file_from_code`, `ios_extract_keys_from_strings_files`, `ios_download_strings_files_from_glotpress` and `ios_merge_strings_files` for typical replacements.
- The action `ios_get_app_version` now requires a parameter `public_version_xcconfig_file` with the public `.xcconfig` file path instead of relying on the environment variable `PUBLIC_CONFIG_FILE`. While the complete removal of this environment variable is our goal, at this point it is still required by other actions such as `ios_bump_version_release` and `ios_codefreeze_prechecks`.
- The usage of a `Deliverfile` (including its `app_version`) is discouraged -- please use `upload_to_app_store` directly from your `Fastfile` instead. Therefore, the parameter `skip_deliver` from the actions `ios_bump_version_hotfix` and `ios_bump_version_release` has been removed.
- The `get_prs_list` action has been removed, as it was not used by client apps anymore. If you were still calling it, check if it was still necessary (were you still doing anything with the file it generated?).
  If you need to generate a list of PRs for other needs—especially generating GitHub Pre-Release or App Center notes for beta builds—you might consider checking `get_prs_between_tags` instead, which behaves slightly differently
  (listing PRs that landed between two builds/tags, rather than PRs associated with a milestone) but should be more flexible and more appropriate for those kind of use cases.

### Clean-ups

- You can now delete the `ENV['APP_STORE_STRINGS_FILE_NAME']` from your Fastfile, as it isn't being used anymore.
- When using the `upload_to_s3` action, replace any use of its `skip_if_exists: true` parameter (resp. `false`) with `if_exists: :skip` (resp. `:fail`).

## From `7.0.0` to `8.0.0`

We are no longer pushing to remote after creating a new commit or a branch. That means, developers need to manually push the changes or add push commands in the project's `Fastfile`. Most importantly, we can no longer immediately trigger beta/final builds after creating a new commit because the changes will not be in remote yet. If you want to keep the existing behavior, you'll need to add a push command before these triggers.

For example, in [WordPress-Android's `new_beta_release` lane](https://github.com/wordpress-mobile/WordPress-Android/blob/0c64cb84c256e004473e97d72b4ac6682ebc140b/fastlane/lanes/release.rb#L86), we download translations, bump the beta version and then trigger a new build in CI. After migrating to `8.0.0` of `release-toolkit`, we'll need to add [`push_to_git_remote`](https://docs.fastlane.tools/actions/push_to_git_remote/) command before this trigger to keep the existing behavior.

## From `6.0.0` to `7.0.0`

Ensure that calls to `ios_bump_version_release` already passed `skip_glotpress: true`.
In case of passing false as parameter or not providing a value (false being the default for this ConfigItem), you'll have to ensure that:
- `download_metadata.swift` isn't being used; if it is, it's a good time to migrate to the new tooling
- You're not relying on `ios_bump_version_release` for commiting the `.po/.pot` file
