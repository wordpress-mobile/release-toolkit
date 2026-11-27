# `release-scan`

Scan a release build for secrets before it ships.

`release-scan` is a command-line tool shipped in this gem, beside the _fastlane_ plugin and independent of it.
It needs [`gitleaks`](https://github.com/gitleaks/gitleaks) on `PATH`, and has been run with gitleaks 8.30.

```sh
bundle exec release-scan path/to/App.xcarchive
```

## Input

`PATH` is what the build produced:

- An `.xcarchive` or `.app` directory. It is copied first and never changed.
- A zip package: `.xcarchive.zip`, `.ipa`, `.apk`, `.aab`, `.apks`.
- A single binary.

## Output

`release-scan/report.md` and `release-scan/report.json` under the working directory, or in `--output DIR`.
Reports are redacted, so the directory is safe to keep as a CI artifact.
Matched values are not written to disk.
A finding names its member, byte offset, a redacted form, and a digest (the first 16 hex chars of its SHA-256).

Exit status:

- `0` when the scan finished and reported nothing at critical or high.
- `1` when it finished and reported a critical or high match.
- `2` when something could not be checked: `gitleaks` is missing, a build or any member of one could not be read, a member or archive is over a size limit, or there was no scannable file.

An error does not discard matches.
They stay in the report and the status is still `2`.

## Rules

A shaped value is 20 to 80 letters and digits, contains both, is not hex, and has Shannon entropy of at least 3.

- A shaped value packed beside a URL, either order, with a gap of 1 to 16 bytes.
- `/token:` followed by a shaped value, including that string inside base64.
- A shaped value assigned to `api_key`, `client_secret`, or `password`, with or without a prefix, in code, JSON, or an XML plist.
- An AWS access key id, a Stripe key, or a Slack bot or user token is critical.
- GitHub, npm, SendGrid, and other Slack tokens are high.
- A PEM private key block with a body is critical. A header with no body is info.
- A Google API key is info.

The vendor token patterns and entropy floors are ported from the gitleaks default config.

## gitleaks

gitleaks runs on the extracted strings, for its long tail of other vendors.
If it is not on `PATH`, the scan exits `2`.
`--no-gitleaks` runs only the built-in rules.

- Generic rules are dropped.
- Private-key, Google, Firebase, Sentry, and JWT rules are counted and not listed.
- AWS, Slack, and Stripe rules are critical.
- Everything else listed is high.

## Coverage

Zip packages are unpacked, including zips nested up to three levels.
Every member is read except debug-symbol paths (`.dSYM`, `dSYMs`) and known media suffixes.
Strings are read as single-byte and UTF-16 LE.

These limits are reported as coverage notes or as an error, not as a clean result:

- Compressed formats (`.gz`, `.xz`, `.exe` installers, `.deb`, `.dmg`, `.pkg`, and similar) are read as outer bytes only.
- A file over 250 MB, or a build expanding past 8 GB or 200,000 entries, is an error.

Binary plists are read as strings, so a key and value in one are not paired.
An `Info.plist` in an IPA is binary, so parsing them to apply the `assigned-secret` rule is the next step.

The scan makes no network calls and does not check whether a value is live.
