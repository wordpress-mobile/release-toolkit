# release-toolkit
Release-toolkit is a collection of [Fastlane](https://fastlane.tools/) actions used to automate some of the steps of the WordPress release process.  

## Integrating the Library 

To install the library, simply add the following lines to your Fastlane Pluginfile:

```bash
gem 'fastlane-plugin-wpmreleasetoolkit', git: 'https://github.com/wordpress-mobile/release-toolkit', tag: '0.6.0' # or the version number you want
```

## Usage

You can use the actions in the library as common Fastlane actions. 
More details about the actions can be found [here](lib/fastlane/plugin/wpmreleasetoolkit/actions/).

## Contributing

Read our [Contributing Guide](CONTRIBUTING.md) to learn about reporting issues, contributing code, and more ways to contribute.

This guide also includes some tips about configuring your environment and IDE (e.g. VSCode) and how to run tests and documentation.

## Doing a new Release

When you need to do a new release of the `release-toolkit`, simply run `rake new_release` and follow the instructions.

> [!NOTE]  
> This task will:
>  - Show you the CHANGELOG/release notes it's about to use for that version
>  - Deduce which version number to use according to [SemVer](https://semver.org/) rules, and ask you to confirm that version number
>  - Create a `release/<x.y>` branch, update the version number in all the right places, and create a PR for those changes

Submit the PR, adding the `Releases` label to it and adding the `@wordpress-mobile/apps-infrastructure` as reviewers.

Once that PR is approved and merged, create a new GitHub Release, copy/pasting the CHANGELOG entries for that GH release's description.

> [!IMPORTANT]  
> Publishing the GitHub Release will create the associated tag as well, which will trigger the CI job that will ultimately `gem push` the gem on RubyGems.

## Security

If you happen to find a security vulnerability, we would appreciate you letting us know at https://hackerone.com/automattic and allowing us to respond before disclosing the issue publicly.

## Getting in Touch ##

If you have questions about getting setup or just want to say hi, join the [WordPress Slack](https://chat.wordpress.org) and drop a message on the `#mobile` channel.

## Resources

- [WordPress Mobile Blog](http://make.wordpress.org/mobile)
- [WordPress Mobile Handbook](http://make.wordpress.org/mobile/handbook/)

## License

Mobile Release Toolkit is an Open Source project covered by the [GNU General Public License version 2](LICENSE).
