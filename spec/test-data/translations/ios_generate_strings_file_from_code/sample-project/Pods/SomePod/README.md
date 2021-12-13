This pod contains some dummy localized text, to test our action parsing source code with `genstrings` to generate the `.strings` files.

In particular, the action will detect:

```swift
    NSLocalizedString("key", comment: "translator context")
    NSLocalizedString("key", value: "English copy", comment: "translator context")
    NSLocalizedString("key", bundle: Bundle(for: BundleToken.self), value: "English copy", comment: "translator context")
    NSLocalizedString("key", tableName: "FileName", value: "English copy", comment: "translator context")
```

But it should not detect the instances of those in `.md` files like this one though.
