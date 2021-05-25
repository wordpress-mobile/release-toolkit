import Foundation
import Cocoa
import CoreText

class TextImage {

    var color = "white"
    var fontSize = 12 {
        didSet {
            stylesheet.fontSize = self.fontSize
        }
    }
    var alignment: NSTextAlignment = .natural

    lazy var stylesheet = Stylesheet(color: self.color, fontSize: self.fontSize)

    internal var html: String = ""

    internal let drawingOptions: NSString.DrawingOptions = [
        .usesLineFragmentOrigin,
        .usesFontLeading
    ]

    init(string: String) throws {

        if isValidFilePath(path: string) {
            html = try contentsOfFile(at: string).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        else {
            html = string
        }
    }

    func draw(inSize size: CGSize) throws -> CGImage? {
        let coreTextStack = try CoreTextStack(html: self.getHTMLData(), size: size, alignment: alignment)
        var fontSize = stylesheet.fontSize

        while(!coreTextStack.fits) {
            fontSize -= 1
            coreTextStack.setFontSize(CGFloat(fontSize))
        }

        return try coreTextStack.draw(inContext: try self.graphicsContext(forSize: size))
    }

    internal func getHTMLData(withConvertedNewlines: Bool = true) -> Data {
        let html = withConvertedNewlines ? self.html.withNewlinesConvertedToBreakTags : self.html
        let fullString = stylesheet.contents + html
        return fullString.data(using: .utf16)!
    }

    func isValidFilePath(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    private func contentsOfFile(at path: String) throws -> String {
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    private func graphicsContext(forSize size: CGSize) throws -> NSGraphicsContext {

        let canvas = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bitmapFormat: .alphaFirst,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        /// Set up the graphics context
        guard let context = NSGraphicsContext(bitmapImageRep: canvas) else {
            throw TextImageProcessingError(kind: .unableToInitializeGraphicsContext)
        }

        return context
    }
}

struct TextImageProcessingError: Error {
    enum ErrorKind: Int {
        case unableToInitializeGraphicsContext
        case unableToDrawImage
        case unableToReadHTMLString
    }

    let kind: ErrorKind
    var localizedDescription: String {
        switch self.kind {
        case .unableToInitializeGraphicsContext: return "Unable to initialize graphics context"
        case .unableToDrawImage: return "Unable to draw image"
        case .unableToReadHTMLString: return "Unable to read input HTML string. It may not be valid HTML"
        }
    }
}
