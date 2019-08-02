import XCTest

class DigitParsingTests: XCTestCase {

    func testThatParsingMixedContentWorks() {
        XCTAssert("$10".digits == 10)
    }

    func testThatParsingUnmixedContentWorks() {
        XCTAssert("10".digits == 10)
    }

    // Yes, this is kinda weird, but CSS + decimal numbers is generally a bad idea anyway
    func testThatParsingDecimalContentWorks() {
        XCTAssert("10.0".digits == 100)
    }

    func testThatParsingNonDigitContentWorks() {
        XCTAssert("Foo".digits == nil)
    }
}
