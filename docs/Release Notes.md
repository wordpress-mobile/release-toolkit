# Release Notes

Release notes are an important part of the release process and we aim to provide high quality notes with our software, by:
1. _Writing the notes collaboratively_, because nobody knows how to describe a feature to the users better than the team that worked on it.
2. _translating them_, so that more people are able to get them.


## Release notes workflow

1. In the root folder of every project, we maintain a `RELEASE-NOTES.txt` file that is updated by every PR that adds a relevant feature. As a reminder to developers and reviewers, we usually add a note about this in the project GitHub PR template. 
2. During code freeze, the `code_freeze` lane of the project's `Fastfile` typically calls at some point:
   - The `extract_release_notes_for_version` action, to extract just the release notes of the version being code-frozen in a separate file (e.g. `WordPress/Resources/release_notes.txt`).
   - Then the `{ios|android}_update_release_notes`  action is then used to add a new empty section at the top of the `RELEASE-NOTES.txt` file, ready for the next version.
3. The Release Manager then shares that file with extracted notes to someone with good wordsmith skills (e.g. we use a freelance writer for WordPress and Jetpack, we have someone in the product team doing that in WooCommerce, …). That person will take that extracted bullet-point list we provide them (which might contain some technical terms and PR links, as those items were written by devs during their PRs) and write an "editorialialized" (aka user-friendly) version of the release notes based on those.
4. That editorialized copy is then used to update the `metadata/release-notes.txt` file, which will contain the "nice" release notes for the current version.
5. The `{ios|an}_update_metadata_source` action is then used to update the `{App|Play}StoreStrings.po` file with the content in `step 4`. That file will later be picked up by a cron job and uploaded to the appropriate GlotPress project dedicated to the release notes and metadata of each app, so that our translators can start translating the release notes.
6. At the end of the beta testing, the `gp_downloadmetadata` action is used to download the translation for the release notes and the other relevant metadata from GlotPress, and update the `fastlane/metadata/{locale}/release_notes.txt` files in fastlane's dedicated folder—ready to be used by `deliver`/`supply` which will take care of using the Apple and Google APIs to upload them in App Store Connect / Play Store Console. 

_Note:_ All these actions need some not-trivial configuration, so it’s usually best to add dedicated lanes in the project and use them to invoke the actions.
