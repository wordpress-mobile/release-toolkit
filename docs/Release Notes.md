# Release Notes

Release notes are an important part of the release process and we aim to provide high quality notes with our software, by:
1. _Writing the notes collaboratively_, because nobody knows how to describe a feature to the users better than the team that worked on it.
2. _translating them_, so that more people are able to get them.


## Manually maintained release notes workflow

1. In the root folder of every project, we maintain a `RELEASE-NOTES.txt` file that is updated by every PR that adds a relevant feature. As a reminder to developers and reviewers, we usually add a note about this in the project GitHub PR template. 
2. During code freeze, the `code_freeze` lane of the project's `Fastfile` typically calls at some point:
   - The `extract_release_notes_for_version` action, to extract just the release notes of the version being code-frozen in a separate file (e.g. `WordPress/Resources/release_notes.txt`).
   - Then the `{ios|android}_update_release_notes`  action is then used to add a new empty section at the top of the `RELEASE-NOTES.txt` file, ready for the next version.
3. The Release Manager then shares that file with extracted notes to someone with good wordsmith skills (e.g. we use a freelance writer for WordPress and Jetpack, we have someone in the product team doing that in WooCommerce, …). That person will take that extracted bullet-point list we provide them (which might contain some technical terms and PR links, as those items were written by devs during their PRs) and write an "editorialialized" (aka user-friendly) version of the release notes based on those.
4. That editorialized copy is then used to update the `metadata/release-notes.txt` file, which will contain the "nice" release notes for the current version.
5. The `{ios|an}_update_metadata_source` action is then used to update the `{App|Play}StoreStrings.po` file with the content in `step 4`. That file will later be picked up by a cron job and uploaded to the appropriate GlotPress project dedicated to the release notes and metadata of each app, so that our translators can start translating the release notes.
6. At the end of the beta testing, the `gp_downloadmetadata` action is used to download the translation for the release notes and the other relevant metadata from GlotPress, and update the `fastlane/metadata/{locale}/release_notes.txt` files in fastlane's dedicated folder—ready to be used by `deliver`/`supply` which will take care of using the Apple and Google APIs to upload them in App Store Connect / Play Store Console. 

_Note:_ All these actions need some not-trivial configuration, so it’s usually best to add dedicated lanes in the project and use them to invoke the actions.


## Generate notes from pull requests at release time

Projects can use `generate_release_notes_file` during code freeze or release preparation instead of editing a shared file in every feature PR. PR titles provide the draft text, and a GitHub release-notes configuration controls which labels are included and how changes are grouped.

The default `format: :release_notes` uses the existing underlined version headings in `RELEASE-NOTES.txt`. To update a Markdown changelog, select the format and path explicitly:

```ruby
generate_release_notes_file(
  repository: 'owner/repository',
  version: '1.2.0',
  tag_name: '1.2.0',
  previous_tag: '1.1.0',
  target_commitish: 'trunk',
  configuration_file_path: '.github/release.yml',
  format: :changelog,
  release_notes_file_path: 'CHANGELOG.md',
  dry_run: true
)
```

Changelog format uses numeric `## <version>` headings, such as `## 1.2.0`, with generated headings nested beneath them. The existing file must have at least one such version section. Introductions, `## Trunk`/`## Unreleased`, and other versions are preserved. A new version is inserted before the first version section; an existing version's entire section is replaced. Pending entries are not automatically moved into the generated version.

Each call writes one file. Projects wanting both files can call the action twice, choosing a configuration for each audience: a developer changelog may include internal changes that store-oriented notes exclude. `format` does not choose a filename or change GitHub filtering. Linked version headings, dates in version headings, and prerelease headings are not supported. Use `#` headings throughout the changelog: underlined Markdown headings are not recognized as section boundaries. Unterminated code fences or HTML comments cause the action to fail without writing.

Use `dry_run: true` to preview, then omit it to write the draft. The action does not commit files. Keep the explicit previous tag and a published target commit; GitHub uses an existing `tag_name` in preference to `target_commitish`. Review the generated text before publishing, and regenerate only before editorial changes because generation replaces the requested version's contents. The existing `extract_release_notes_for_version` action supports the underlined format only.
