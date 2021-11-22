import Foundation

enum AppClass1 {
    static let appString1 = NSLocalizedString("app.key1", comment: "App key 1, no value")
    static let appString2 = NSLocalizedString("app.key2",
                                              value: "appvalue2, %1$@.",
                                              comment: "App key 2, with value containing placeholder.")
    static let appString3 = NSLocalizedString("app.key3.%1@d",
                                              comment: "App key 3, no value, with key containing placeholder, "
                                                + "and with comment literal spanning multiple lines in code.")
    static let appString4 = NSLocalizedString("app.key4",
                                              bundle: Bundle(for: BundleToken.self),
                                              value: "appvalue4, %1$@.",
                                              comment: "App key 4, with value, bundle and placeholder.")
    static let appString5 = NSLocalizedString("app.key5", tableName: "AppStrings",
                                              value: "app value 5\n"
                                                + "with multiple lines.",
                                              comment: "App key 5, with value, custom table and placeholder.")
}

private final class BundleToken {}
