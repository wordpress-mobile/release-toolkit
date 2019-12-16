# How to Contribute

First off, thank you for contributing! We're excited to collaborate with you! 🎉

The following is a set of guidelines for the many ways you can join our collective effort.


## Reporting Bugs, Asking Questions, and Suggesting Features

Have a suggestion or feedback? Please go to [Issues](https://github.com/wordpress-mobile/release-toolkit/issues) and [open a new issue](https://github.com/wordpress-mobile/release-toolkit/issues/new). Prefix the title with a category like _"Bug:"_, _"Question:"_, or _"Feature Request:"_. Screenshots help us resolve issues and answer questions faster, so thanks for including some if you can.

## Submitting Code Changes

You're more than welcome to visit the [Issues](https://github.com/wordpress-mobile/release-toolkit/issues) page and pick an item that interests you.

We always try to avoid duplicating efforts, so if you decide to work on an issue, leave a comment to state your intent. If you choose to focus on a new feature or the change you’re proposing is significant, we recommend waiting for a response before proceeding. The issue may no longer align with project goals.

If the change is trivial, feel free to send a pull request without notifying us.

### Pull Requests and Code Reviews

All code contributions pass through pull requests. If you haven't created a pull request before, we recommend this free video series, [How to Contribute to an Open Source Project on GitHub](https://egghead.io/courses/how-to-contribute-to-an-open-source-project-on-github).

The core team monitors and reviews all pull requests. Depending on the changes, we will either approve them or close them with an explanation. We might also work with you to improve a pull request before approval.

We do our best to respond quickly to all pull requests. If you don't get a response from us after a week, feel free to reach out to us via Slack.

## Code Style
While we don't have a full set of coding guidelines in place for this repository yet, here are a few guidelines that will make it more likely for your PR to be accepted:

- New functionality should have appropriate test coverage.
- Prefer expressing your intent using Ruby over calling out to `sh` to accomplish a task where possible – this makes it more likely that our code will work cross-platform, makes it possible to mock dependencies, and allows the project to explicitly define dependencies via the Gemfile (rather than implicitly via command-line calls to specific tools).
- Bias towards producing verbose output – the tooling should give lots of information to the developer as it's accomplishing its task, and it should always be clear what step of the process is currently being executed. Most of the code will run on CI and build machines, so being able to go back and debug issues is top priority.

## Getting in Touch

If you have questions or just want to say hi, join the [WordPress Slack](https://make.wordpress.org/chat/) and drop a message on the `#mobile` channel.