import Foundation
import Cocoa

extension String {
    var digits: Int? {
        let digits = self
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        return Int(digits)
    }

    var withNewlinesConvertedToBreakTags: String {
        return self.replacingOccurrences(of: "\n", with: "<br />")
    }
}

extension NSTextAlignment {
    static func fromString(_ string: String) -> NSTextAlignment {
        switch string.lowercased() {
        case "left": return .left
        case "center": return .center
        case "right": return .right
        default: return .natural
        }
    }
}
