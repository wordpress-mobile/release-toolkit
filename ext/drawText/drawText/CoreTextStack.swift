import Cocoa
import CoreGraphics

struct CoreTextStack {

    let layoutManager: NSLayoutManager
    let textContainer: NSTextContainer
    var textStorage: NSTextStorage

    let frameSize: CGSize
    var alignment: NSTextAlignment

    enum Errors: Error {
        case unableToInitializeTextStorage
    }

    init(html: Data, size: CGSize, alignment: NSTextAlignment = .natural) throws {

        guard let textStorage = NSTextStorage(html: html, documentAttributes: nil) else {
            throw Errors.unableToInitializeTextStorage
        }

        ///Storage
        self.textStorage = textStorage
        self.textContainer = NSTextContainer(size: size)
        self.layoutManager = NSLayoutManager()
        self.frameSize = size
        self.alignment = alignment

        /// Setup
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        /// Configuration
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        layoutManager.usesFontLeading = true
        layoutManager.typesetter.lineFragmentPadding = 0

        applyParagraphStyles()
    }

    func setFontSize(_ size: CGFloat) {

        /// Process each attribute run separately so that if the first word is bold,
        /// it doesn't make all of the words bold.
        textStorage.attributeRuns.forEach {

            let range = NSRange(location: 0, length: $0.length)

            $0.font = NSFont(name: $0.font!.fontName, size: size)
            $0.edited(.editedAttributes, range: range, changeInLength: 0)
            $0.fixAttributes(in: range)
        }

        applyParagraphStyles()
    }

    mutating func setAlignment(_ alignment: NSTextAlignment) {
        self.alignment = alignment
        applyParagraphStyles()
    }

    func applyParagraphStyles() {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = 0
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.alignment = self.alignment
        
        textStorage.addAttributes([
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ], range: range)
        textStorage.edited(.editedAttributes, range: range, changeInLength: 0)
        textStorage.fixAttributes(in: range)
    }

    func draw(inContext context: NSGraphicsContext) throws -> CGImage {
        NSGraphicsContext.saveGraphicsState()

        /// Without the transform, text is drawn upside down and backwards because of
        /// macOS' flipped coordinate system.
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
        let transform = NSAffineTransform()
        transform.scaleX(by: 1, yBy: -1)
        transform.translateX(by: 0, yBy: frameSize.height * -1)
        transform.concat()

        layoutManager.drawGlyphs(forGlyphRange: range, at: .zero)

        guard let image = context.cgContext.makeImage() else {
            throw TextImageProcessingError(kind: .unableToDrawImage)
        }
        NSGraphicsContext.restoreGraphicsState()

        return image
    }

    /// `fits` is used to determine whether we should shrink the font size in order to fit the text in
    /// a smaller box. Turns out the best way to do that is to check whether all the characters fit into
    /// the textContainer, rather than trying to measure the drawing area.
    var fits: Bool {

        let textStorageLength = textStorage.length
        let textContainerRange = layoutManager.glyphRange(for: textContainer)

        return textStorageLength == textContainerRange.length
    }

    var range: NSRange {
        return layoutManager.glyphRange(for: textContainer)
    }
}
