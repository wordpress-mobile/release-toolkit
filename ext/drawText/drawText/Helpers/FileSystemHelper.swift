import Foundation
import Cocoa

struct File {

    static func write(image: CGImage, toFileAtPath path: String) {

        /// Turn it into a `png`
        let rep = NSBitmapImageRep(cgImage: image)
        let pngData = rep.representation(using: .png, properties: [:])

        /// Then write it out to the provided path
        do {
            let pathString = NSString(string: path).expandingTildeInPath
            let output = NSURL(fileURLWithPath: pathString)

            try pngData?.write(to: output as URL)
        }
        catch let err {
            printError("Unable to write image to \(path): \(err.localizedDescription)")
            exit(6)
        }
    }
}
