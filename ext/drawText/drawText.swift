#!/usr/bin/swift

import Foundation
import Cocoa
import CoreText


/// First, some helpers
///
func commandLineArguments() -> [String : String] {

    return CommandLine.arguments
        .filter{ $0.contains("=") }
        .reduce([String : String](), { (dictionary, argument) -> [String : String] in

            var dictionary = dictionary //shadow for mutability

            var parts = argument.split(separator: "=")
            dictionary[String(parts.remove(at: 0))] = parts.joined(separator: "=")

            return dictionary
        })
}

func printUsageAndExit() -> Never {
    print("""
    Usage: ./draw-text
        html={file path or quotes-enclosed HTML string [required]}
        maxWidth={ integer [required] }
        maxHeight={ integer [required] }
        fontSize={ CSS-size compatible string [default = 12px }
        color={ color or hex code [default = white] }
        align={ CSS text-alignment value [default = center] }
        stylesheet={ File Path to a custom stylesheet [default = none] }
    """)
    exit(1)
}

func printError(_ string: String) {
    let redColor = "\u{001B}[0;31m"
    let endColor = "\u{001B}[0;m"
    fputs("\(redColor)Error: \(string)\(endColor)\n", stderr)
}

func applyCustomStyles(to styles: String, from path: String?) -> String {

    guard let path = path,
        FileManager.default.fileExists(atPath: path),
        let fileContents = FileManager.default.contents(atPath: path),
        let externalStyles = String(bytes: fileContents, encoding: .utf8) else {
            return styles
        }

    return styles.replacingOccurrences(of: "/* EXTERNAL STYLES */", with: externalStyles)
}

let args = commandLineArguments()

let drawingOptions: NSString.DrawingOptions = [
    .usesLineFragmentOrigin,
    .usesFontLeading,
]

// Read the HTML string out of the args. This can either be raw HTML, or a path to an HTML file
guard let htmlString = args["html"] else {
    printError("Unable to read HTML string")
    printUsageAndExit()
}

guard let maxWidthString = args["maxWidth"] else {
    printError("Missing maxWidth argument")
    printUsageAndExit()
}

guard let maxHeightString = args["maxHeight"] else {
    printError("Missing maxHeight argument")
    printUsageAndExit()
}

guard let maxWidth = Int(maxWidthString) else {
    printError("maxWidth must be an integer")
    printUsageAndExit()
}

guard let maxHeight = Int(maxHeightString) else {
    printError("maxHeight must be an integer")
    printUsageAndExit()
}

let color = args["color"] ?? "white"
let fontSize = args["fontSize"] ?? "12px"
let alignment = args["align"] ?? "center"

var styleString = """
<style>
*{
    padding: 0;
    margin: 0;
    color: \(color);
    font-size: \(fontSize);
    text-align: \(alignment);
}

/* EXTERNAL STYLES */
</style>
"""

let possibleFilePath = NSString(string: htmlString).expandingTildeInPath

styleString = applyCustomStyles(to: styleString, from: args["stylesheet"])

// Convert the HTML to data
if FileManager.default.fileExists(atPath: possibleFilePath) {
    let fileContents = try! String(contentsOfFile: possibleFilePath, encoding: .utf8)
    styleString += fileContents.replacingOccurrences(of: "\n", with: "<br />")
}
// If there's no file at that location, treat the argument as the string to be drawn
else{
   styleString += htmlString
}

// NSMutableAttributedSting uses utf16 internally, so encode it that way
let stringData = styleString.data(using: .utf16)!

// Ensure that the HTML data was valid
guard let attributedString = NSMutableAttributedString(html: stringData, documentAttributes: nil) else{
    printError("Unable to read HTML string")
    exit(1)
}

let outputRect = attributedString.boundingRect(with: CGSize(width: maxWidth, height: maxHeight), options: drawingOptions)

/// Ensure that the text can be drawn inside the provided dimensions
let fittingSize = CGSize(width: outputRect.width, height: CGFloat.greatestFiniteMagnitude)
let fittingRect = attributedString.boundingRect(with: fittingSize, options: drawingOptions)

guard fittingRect.height <= outputRect.height else {
    printError("Provided string (\(attributedString))doesn't fit in the provided dimensions")
    exit(1)
}

// Create a bitmap canvas to draw this image onto
guard let canvas = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(outputRect.width),
    pixelsHigh: Int(outputRect.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .calibratedRGB,
    bitmapFormat: .alphaFirst,
    bytesPerRow: 0,
    bitsPerPixel: 0
    ) else {
        printError("Invalid HTML String")
        exit(3)
}

/// Set up the graphics context
guard let context = NSGraphicsContext(bitmapImageRep: canvas) else {
    printError("Unable to initialize graphics context")
    exit(4)
}
/// Make it the current context (needed for command-line string drawing)
NSGraphicsContext.current = context

/// Draw the string
let ctx = NSStringDrawingContext()
ctx.minimumScaleFactor = 1.0
attributedString.draw(with: outputRect, options: drawingOptions, context: ctx)

/// Draw the image into a `CIImage`
guard let image = context.cgContext.makeImage()?.cropping(to: ctx.totalBounds) else {
    printError("Unable to draw image")
    exit(5)
}

/// Turn it into a `png`
let rep = NSBitmapImageRep(cgImage: image)
let pngData = rep.representation(using: .png, properties: [:])

/// Write it out to file
let outputPath = args["output"] ?? "output.png"

do {
    let pathString = NSString(string: outputPath).expandingTildeInPath
    let output = NSURL(fileURLWithPath: pathString)

    try pngData?.write(to: output as URL)
}
catch let err {
    printError("Unable to write image to \(outputPath): \(err.localizedDescription)")
    exit(6)
}
