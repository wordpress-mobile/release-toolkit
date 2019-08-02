import Foundation

func readCommandLineArguments() -> [String : String] {

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
