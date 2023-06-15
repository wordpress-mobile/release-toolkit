# Migration Instructions for Major Releases

### From `8.x` to `9.0.0`

In `upload_to_s3` calls, replace `skip_if_exists: true` with `if_exists: :skip` and `skip_if_exists: false` with `if_exists: :fail`. I `skip_if_exists` is not specified, no change is necessary.

### From `7.x` to `8.0.0`

We are no longer pushing to remote after creating a new commit or a branch. That means, developers need to manually push the changes or add push commands in the project's `Fastfile`. Most importantly, we can no longer immediately trigger beta/final builds after creating a new commit because the changes will not be in remote yet. If you want to keep the existing behavior, you'll need to add a push command before these triggers.

For example, in [WordPress-Android's `new_beta_release` lane](https://github.com/wordpress-mobile/WordPress-Android/blob/0c64cb84c256e004473e97d72b4ac6682ebc140b/fastlane/lanes/release.rb#L86), we download translations, bump the beta version and then trigger a new build in CI. After migrating to `8.0.0` of `release-toolkit`, we'll need to add [`push_to_git_remote`](https://docs.fastlane.tools/actions/push_to_git_remote/) command before this trigger to keep the existing behavior.
