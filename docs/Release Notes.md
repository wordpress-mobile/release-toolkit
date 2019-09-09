# Release Notes
Release notes are an important part of the release process and we aim to provide high quality notes with our software, by:
1. _Writing the notes collaboratively_, because nobody knows how to describe a feature to the users better than the team that worked on it.
2. _translating them_, so that more people are able to get them.


## Release notes workflow
1. In the root folder of every project, we maintain a `RELEASE-NOTES.txt` file that is updated by every PR that adds a relevant feature. As a reminder to developers and reviewers, we usually add a note about this in the project GitHub PR template. 
2. The `get_prs_list_action` action provides a list of all the merged PRs  in a range of tags. 
3. During the code freeze, the release manager gets the release notes from `step 1` , uses `step 2` to get the list of merged PRs to verify/integrate the notes and write down the final copy.
4. The copy is used to update the `metadata/release-notes.txt` file which contains only the release notes for the current version.
5. The `xx_update_release_notes`  action is used to update `metadata/app_store_strings.pot` with the content in `step 4`.
6. `metadata/app_store_strings.pot` is uploaded to GlotPress for translations.
7. At the end of the beta testing, the `xx_update_metadata` action is used to download the translation for the release notes and the other relevant metadata from GlotPress. 

_Note:_ All these actions need some not-trivial configuration, so it’s usually best to add related lanes in the project and use them to invoke the actions.

