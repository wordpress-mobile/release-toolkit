# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Overview

Release Toolkit is a fastlane plugin  implemented as a Ruby gem (`fastlane-plugin-wpmreleasetoolkit`) providing actions and helper utilities for release automation of Automattic's mobile apps. It standardizes the release process across multiple products (WordPress, Jetpack, WooCommerce, DayOne, PocketCats, Tumblr, Studio, …), repositories, and platforms (iOS, Android, macOS).

- **Language**: Ruby (version in `.ruby-version`, minimum in `fastlane-plugin-wpmreleasetoolkit.gemspec`)
- **Framework**: Fastlane plugin
- **License**: GPLv2
- **Main branch**: `trunk`
- **Gem version**: defined in `lib/fastlane/plugin/wpmreleasetoolkit/version.rb`

## Build and Development Commands

```sh
bundle install                          # Install dependencies
bundle exec rspec                       # Run all tests
bundle exec rspec spec/path_spec.rb     # Run a single test file
bundle exec rubocop                     # Run linter
bundle exec rubocop -a                  # Auto-fix lint issues
bundle exec yard doc                    # Generate docs, open in browser
bundle exec yard stats --list-undoc     # Show undocumented methods
gem build                               # Build the gem (no arguments — auto-picks the gemspec)
rake new_release                        # Start a new release (interactive)
```

## Project Structure

```
lib/fastlane/plugin/wpmreleasetoolkit/
├── actions/              # Fastlane actions (entry points)
│   ├── android/          # Android-specific actions
│   ├── common/           # Cross-platform actions
│   ├── configure/        # Project configuration actions
│   └── ios/              # iOS-specific actions
├── helper/               # Business logic modules and classes
│   ├── android/          # Android helpers
│   ├── ios/              # iOS helpers
│   └── metadata/         # Metadata/PO file generation
├── models/               # Data model classes
├── versioning/           # Version management system
│   ├── calculators/      # Version number calculation strategies
│   ├── files/            # Platform-specific version file I/O
│   └── formatters/       # Version string formatting strategies
└── version.rb            # Gem version constant
spec/                     # RSpec tests (mirrors lib/ structure)
rakelib/                  # Rake task helpers
docs/                     # Additional documentation
```

## Code Patterns

### Actions

All actions inherit from `Fastlane::Action` and follow this structure:

```ruby
module Fastlane
  module Actions
    class MyAction < Action
      def self.run(params)
        # Implementation — delegate business logic to helpers
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :param_name,
            env_name: 'ENV_VAR_NAME',
            description: 'Description',
            optional: false,
            type: String
          ),
        ]
      end

      def self.description
        'One-line description'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
```

Key conventions:
- Actions orchestrate; helpers contain business logic.
- Use `UI.user_error!` for validation failures, `UI.message`/`UI.success` for output.
- Shell commands go through `Action.sh('command', *args)`.
- Config items support `env_name` for environment variable fallback and `verify_block` for validation.

### Helpers

- **Modules** (static methods) for stateless utilities: `GitHelper`, `GlotPressHelper`.
- **Classes** for stateful operations: `GithubHelper` (wraps Octokit), `ConfigureHelper`.
- Platform-specific helpers live in `helper/android/` and `helper/ios/`.

### Versioning System

Uses a strategy pattern with three layers:
- **Calculators** compute the next version (semantic, date-based, marketing).
- **Formatters** convert between strings and `AppVersion` objects.
- **Files** read/write platform-specific version files (`.xcconfig`, `version.properties`).

All have abstract base classes (`AbstractVersionCalculator`, `AbstractVersionFormatter`).

### Models

Simple data classes in `models/`: `AppVersion`, `BuildCode`, `Configuration`, `FileReference`, and Firebase-related models.

## Testing

- **Framework**: RSpec (config in `.rspec`)
- **HTTP mocking**: WebMock (real HTTP requests are disabled)
- **Test data**: Fixtures in `spec/test-data/`

### Custom Test Helpers (defined in `spec/spec_helper.rb`)

| Helper | Purpose |
|--------|---------|
| `run_described_fastlane_action(params)` | Run the action being described in a test lane |
| `allow_fastlane_action_sh` | Enable `Action.sh` in test environment |
| `expect_shell_command(*cmd, exitstatus:, output:)` | Assert shell command execution |
| `sawyer_resource_stub(**fields)` | Mock GitHub API (Sawyer) responses |
| `in_tmp_dir { \|tmpdir\| ... }` | Execute block in a temporary directory |
| `with_tmp_file(named:, content:) { \|path\| ... }` | Execute block with a temporary file |

## Style Guide (RuboCop)

Configuration is in `.rubocop.yml`. Key rules:

- **Trailing commas** in multi-line arrays are required (`consistent_comma`) for cleaner diffs.
- **Hash shorthand syntax** is disallowed (`{a:, b:}` — use `{a: a, b: b}`).
- **Empty methods** must use expanded style (multi-line `def ... end`).
- **Unused method arguments** are allowed (common in action API contracts).
- `Style/StringConcatenation` is disabled due to `Pathname#+` issues.
- `Style/FetchEnvVar` is disabled.
- Generous metric limits (e.g., line length 300, method length 150).
- RSpec cops: `ExampleLength`, `MultipleMemoizedHelpers`, `MultipleExpectations` are disabled.

## CI/CD

### Buildkite (primary CI)

Pipeline defined in `.buildkite/pipeline.yml`:
- **Tests**: RSpec on macOS agents with Ruby matrix.
- **Linters**: RuboCop and Danger run on PRs only.
- **Gem publishing**: Automatic on git tag creation (pushes to RubyGems).

### GitHub Actions

Single workflow (`.github/workflows/run-danger.yml`) triggers Danger checks on Buildkite for PR events.

### Danger Checks (Dangerfile)

Automated PR checks include:
- RuboCop lint (full scan, inline comments, fails on violations).
- `Gemfile.lock` update verification.
- Version consistency between `version.rb` and `Gemfile.lock`.
- CHANGELOG.md modification required.
- PR diff size limit (500 lines).
- Label checks (`Do Not Merge`).
- Reviewer assignment reminder.
- Draft PRs skip some checks.

## Pull Request Checklist

From `.github/PULL_REQUEST_TEMPLATE.md`:
1. Run `bundle exec rubocop` — no violations.
2. Add unit tests in `spec/`.
3. Run `bundle exec rspec` — all tests pass.
4. Add a CHANGELOG.md entry under the `## Trunk` section.
5. Add a MIGRATION.md entry if there are breaking changes.

## CHANGELOG Conventions

The CHANGELOG uses these sections under each version:
- `### Breaking Changes`
- `### New Features`
- `### Bug Fixes`
- `### Internal Changes`

Unreleased changes go under `## Trunk`. Empty sections use `_None_` as placeholder. Entries reference PR numbers: `[#123]`.

Version bump semantics: Breaking Changes = major, New Features = minor, Bug Fixes/Internal = patch.

## Release Process

1. `rake new_release` — interactive task that:
   - Parses CHANGELOG for pending changes and suggests the next semantic version.
   - Creates a `release/<version>` branch.
   - Updates `version.rb`, `Gemfile.lock`, and CHANGELOG.
   - Commits, pushes, and opens a draft PR.
2. After PR merge, create a GitHub Release targeting `trunk`.
3. The GitHub Release creates a git tag, which triggers Buildkite to publish the gem to RubyGems.

## Key Dependencies

Runtime and development dependencies with version constraints are defined in `fastlane-plugin-wpmreleasetoolkit.gemspec` and `Gemfile`. Key runtime dependencies include:

- **fastlane** — plugin framework
- **octokit** — GitHub API
- **git** — git operations
- **xcodeproj** — Xcode project files
- **nokogiri** — XML parsing
- **gettext** — i18n/PO files
- **google-cloud-storage** — GCS uploads
- **buildkit** — Buildkite API
