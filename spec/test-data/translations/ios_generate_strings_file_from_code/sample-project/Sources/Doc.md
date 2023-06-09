This app will be translated via our `ios_generate_strings_file_from_code` fastlane action which will generate the appropriate `.strings` files.

In particular, the action will detect the following in your Swift code:

```swift
    NSLocalizedString("key", comment: "translator context")
    NSLocalizedString("key", value: "English copy", comment: "translator context")
    NSLocalizedString("key", bundle: Bundle(for: BundleToken.self), value: "English copy", comment: "translator context")
    NSLocalizedString("key", tableName: "FileName", value: "English copy", comment: "translator context")
```

And also similar calls in your Objective-C code, and `Text(…)` calls in SwiftUI.

Note that it should not detect the instances of those in `.md` files like this one though.
