import XCTest

class TextImageTests: DrawTextTest {

    func testThatInitializingWithAValidFilePathReadsTheFileCorrectly() {
        let path = getTestCaseURLForAsset(named: "regular-text-block").path
        let image = try! TextImage(string: path)

        XCTAssertEqual(image.html, getTestCase(named: "regular-text-block"))
    }

    func testDrawingOversizedSingleLineText() {
        let string = "playstoreres/metadata/source/play_store_screenshot_7.html"
        try! TextImage(string: string)
            .applying(fontSize: 140)
            .draw(toFileNamed: "\(#function).png")
    }

    func testDrawingRealText() {

        regularTextBlock()
            .draw(toFileNamed: "\(#function).png")
    }

    func testDrawingLongText() {

        let string = getTestCase(named: "large-text-block")
        try! TextImage(string: string)
            .applying(fontSize: 140)
            .draw(toFileNamed: "\(#function).png")
    }

    func testDrawingCenteredText() {

        regularTextBlock()
            .applying(fontSize: 100)
            .applying(alignment: .center)
            .draw(toFileNamed: "\(#function).png")
    }

    func testDrawingRTLLanguages() {

        let string = getTestCase(named: "rtl-text-block")
        try! TextImage(string: string)
            .applying(fontSize: 100)
            .applying(alignment: .center)
            .draw(toFileNamed: "\(#function).png")
    }


    private func regularTextBlock() -> TextImage {
        let string = getTestCase(named: "regular-text-block")
        return try! TextImage(string: string)
            .applying(fontSize: 100)    // use a sensible default font size
    }
}

fileprivate extension TextImage {
    func applying(styleRule rule: String) -> TextImage {
        self.stylesheet.externalStyles = """
        *{
        \(rule)
        }
        """

        return self
    }

    func applying(fontSize size: Int) -> TextImage {
        self.fontSize = size
        return self
    }

    func applying(alignment: NSTextAlignment) -> TextImage {
        self.alignment = alignment
        return self
    }

    @discardableResult
    func draw(toFileNamed fileName: String) -> TextImage {
        let output = try! self.draw(inSize: CGSize(width: 500, height: 500))!
        
        let outputDirectory = String(packageRootPath + "/test-output/")

        File.write(image: output, toFileAtPath: outputDirectory + fileName)

        return self
    }

    var packageRootPath: String {
        let packageRootPath = URL(fileURLWithPath: #file)
            .pathComponents
            .prefix(while: { $0 != "drawText Tests" })
            .joined(separator: "/")
            .dropFirst()

        return String(packageRootPath)
    }
}
