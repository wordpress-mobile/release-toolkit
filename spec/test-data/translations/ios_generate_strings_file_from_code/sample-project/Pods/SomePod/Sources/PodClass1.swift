import Foundation

enum PodClass1 {
    static let podString1 = NSLocalizedString("pod.key1", comment: "Pod key 1, no value")
    static let podString2 = NSLocalizedString("pod.key2",
                                              value: "podvalue2, %1$@.",
                                              comment: "Pod key 2, with value containing placeholder.")
    static let podString3 = NSLocalizedString("pod.key3.%1@d",
                                              comment: "Pod key 3, no value, with key containing placeholder,"
                                                + "and with multi-line comment")
    static let podString4 = NSLocalizedString("pod.key4",
                                              bundle: Bundle(for: BundleToken.self),
                                              value: "podvalue4, %1$@.",
                                              comment: "Pod key 4, with value, bundle and placeholder.")
    static let podString5 = NSLocalizedString("pod.key5",
                                              tableName: "PodStrings",
                                              value: "pod value 5\n"
                                                + "with multiple lines.",
                                              comment: "Pod key 5, with value, custom table and placeholder.")
    static let podStringX = PodLocalizedString("pod.custom_l10n_function",
                                               value: "Using custom macro \n"
                                                    + "with multiple lines.",
                                               comment: """
                                               A string processed via a custom macro
                                               instead of the standard NSLocalizedString one.
                                               """)
}

private final class BundleToken {}
