import SwiftUI

struct AppSampleView: View {
    var body: some View {
      VStack {
        Text("app.swiftui.key1") // You should always provide a comment, not providing one like here is bad practice
        Text("app.swiftui.key2", comment: "App SwiftUI key 2")
        Text("app.swiftui.key3",
             tableName: "AppStrings",
             comment: """
                App SwiftUI key 3
                With comment spanning on multiple lines
                """
        )
        Text("app.swiftui.key4",
             bundle: Bundle(for: BundleToken.self),
             comment: "App SwiftUI key 4"
        )
      }
    }
}

private final class BundleToken {}
