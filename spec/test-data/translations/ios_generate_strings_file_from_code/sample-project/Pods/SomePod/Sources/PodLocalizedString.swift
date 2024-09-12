import Foundation

func PodLocalizedString(_ key: String, value: String? = nil, comment: StaticString) -> String {
    Bundle(for: BundleToken.self).localizedString(forKey: key, value: value, table: nil)
}
