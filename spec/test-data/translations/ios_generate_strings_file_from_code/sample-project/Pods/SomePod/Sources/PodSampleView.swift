import SwiftUI

struct PodSampleView: View {
    var body: some View {
      VStack {
        Text("pod.swiftui.key1") // You should always provide a comment, not providing one like here is bad practice
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
