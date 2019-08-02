import XCTest

class DrawTextTest: XCTestCase {

    internal func getTestCase(named name: String) -> String {
        let url = getTestCaseURLForAsset(named: name)
        return try! String(contentsOf: url)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    internal func getTestCaseURLForAsset(named name: String, extension: String = "txt") -> URL {
        return Bundle(for: self.classForCoder).url(forResource: name, withExtension: `extension`)!
    }
}
