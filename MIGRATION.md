# Release Toolkit Migration Guide

---

## Migrating to Trunk

### Considerations for breaking changes

- Ensure that calls to `ios_bump_version_release` already passed `skip_glotpress: true`.
In case of passing false as parameter or not providing a value (false being the default for this ConfigItem), you'll have to ensure that:
  - `download_metadata.swift` isn't being used; if it is, it's a good time to migrate to the new tooling
  - You're not relying on `ios_bump_version_release` for commiting the `.po/.pot` file
- The deprecated actions `ios_localize_project` and `ios_update_metadata` were now completely removed. If your project is still using them, please use the new tooling instead.
  - See `ios_generate_strings_file_from_code`, `ios_extract_keys_from_strings_files`, `ios_download_strings_files_from_glotpress` and `ios_merge_strings_files` for typical replacements.
- The action `ios_get_app_version` now requires a parameter `public_version_xcconfig_file` with the public `.xcconfig` file path instead of relying on the environment variable `PUBLIC_CONFIG_FILE`. While the complete removal of this environment variable is our goal, at this point it is still required by other actions such as `ios_bump_version_release` and `ios_codefreeze_prechecks`.
- The usage of a `Deliverfile` (including its `app_version`) is discouraged -- please use `upload_to_app_store` directly from your `Fastfile` instead. Therefore, the parameter `skip_deliver` from the actions `ios_bump_version_hotfix` and `ios_bump_version_release` has been removed.

### Clean-ups

- You can now delete the `ENV['APP_STORE_STRINGS_FILE_NAME']` from your Fastfile, as it isn't being used anymore.
