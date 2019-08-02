import Cocoa

struct Stylesheet {

    var contents: String = ""
    var externalStyles = "/* EXTERNAL STYLES */"

    private let color: String

    init(color: String, fontSize: Int) {
        self.fontSize = fontSize
        self.color = color

        update()
    }

    mutating func updateWith(filePath: String) {

        guard
            FileManager.default.fileExists(atPath: filePath),
            let fileContents = FileManager.default.contents(atPath: filePath),
            let externalStyles = String(bytes: fileContents, encoding: .utf8) else {
                return
        }

        self.externalStyles = externalStyles
        update()
    }

    var fontSize: Int {
        didSet { update() }
    }

    fileprivate mutating func update() {
        self.contents = """
        <style>
        * {
        padding: 0;
        margin: 0;
        color: \(color);
        font-size: \(fontSize)px;
        }

        \(externalStyles)
        </style>
        """.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
