import Foundation
import Cocoa

let args = readCommandLineArguments()

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

do {
    let textImage = try TextImage(string: htmlString)

    if let color = args["color"] {
        textImage.color = color
    }

    if let fontSize = args["fontSize"]?.digits {
        textImage.fontSize = fontSize
    }

    if let alignment = args["alignment"] {
        textImage.alignment = NSTextAlignment.fromString(alignment)
    }

    if let stylesheetPath = args["stylesheet"] {
        textImage.stylesheet.updateWith(filePath: stylesheetPath)
    }

    let outputPath = args["output"] ?? "output.png"

    let size = CGSize(width: maxWidth, height: maxHeight)
    let image = try textImage.draw(inSize: size)!

    File.write(image: image, toFileAtPath: outputPath)
}
catch let err {
    print(err.localizedDescription)
    exit(1)
}
