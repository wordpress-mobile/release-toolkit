import SwiftUI

struct PodSampleView: View {
    var body: some View {
      VStack {
        // Unfortunately, `Text.init` does not force you to provide an explicit `comment` parameter,
        // while it is highly recommended to provide one for giving context to translators.
        // But since this is sadly likely the most common form we might see (`comment` being optional),
        // We still want to make sure our tooling handles that case.
        Text("pod.swiftui.key1")
        Text("pod.swiftui.key2", comment: "Pod SwiftUI key 2")
        Text("pod.swiftui.key3",
             tableName: "PodStrings",
             comment: """
                Pod SwiftUI key 3
                With comment spanning on multiple lines
                """
        )
        Text("pod.swiftui.key4",
             bundle: Bundle(for: BundleToken.self),
             comment: "Pod SwiftUI key 4"
        )
      }
    }
}

private final class BundleToken {}
