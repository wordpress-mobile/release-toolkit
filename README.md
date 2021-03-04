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

## Security

If you happen to find a security vulnerability, we would appreciate you letting us know at https://hackerone.com/automattic and allowing us to respond before disclosing the issue publicly.

## Getting in Touch ##

If you have questions about getting setup or just want to say hi, join the [WordPress Slack](https://chat.wordpress.org) and drop a message on the `#mobile` channel.

## Resources

- [WordPress Mobile Blog](http://make.wordpress.org/mobile)
- [WordPress Mobile Handbook](http://make.wordpress.org/mobile/handbook/)

## License

Mobile Release Toolkit is an Open Source project covered by the [GNU General Public License version 2](LICENSE).