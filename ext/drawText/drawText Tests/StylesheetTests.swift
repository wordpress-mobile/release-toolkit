import XCTest

class StylesheetTests: DrawTextTest {

    func testThatDefaultStylesheetProducesValidOutput() {
        let stylesheet = Stylesheet(color: "black", fontSize: 10)
        XCTAssert(stylesheet.contents == getTestCase(named: "default-stylesheet"))
    }

    func testThatStylesheetCanChangeFontSizes() {
        var stylesheet = Stylesheet(color: "black", fontSize: 10)
        stylesheet.fontSize -= 1
        XCTAssert(stylesheet.contents == getTestCase(named: "text-size-adjustment-test"))
    }

    func testThatStylesheetExternalStylesCanBeUpdated() {
        var stylesheet = Stylesheet(color: "black", fontSize: 10)
        stylesheet.updateWith(filePath: getTestCaseURLForAsset(named: "external-styles-sample", extension: "css").path)
        XCTAssert(stylesheet.contents == getTestCase(named: "external-styles-test"))
    }

    func testThatUpdatingExternalStylesWithAnInvalidPathProducesAValidStylesheet() {
        var stylesheet = Stylesheet(color: "black", fontSize: 10)
        stylesheet.updateWith(filePath: "/this-is-a-fake-path-that-should-never-exist")

        debugPrint(stylesheet.contents, getTestCase(named: "default-stylesheet"))


        XCTAssert(stylesheet.contents == getTestCase(named: "default-stylesheet"))
    }
}
