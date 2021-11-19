import SwiftUI

struct AppSampleView: View {
    var body: some View {
      VStack {
        // Unfortunately, `Text.init` does not force you to provide an explicit `comment` parameter,
        // while it is highly recommended to provide one for giving context to translators.
        // But since this is sadly likely the most common form we might see (`comment` being optional),
        // We still want to make sure our tooling handles that case.
        Text("app.swiftui.key1")
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
