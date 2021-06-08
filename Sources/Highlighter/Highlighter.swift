import Foundation
import JavaScriptCore

#if os(OSX)
import AppKit
#endif

open class Highlighter {

    /*
     * Utility class for generating a highlighted NSAttributedString from a String.
     */

    // MARK: Public Properties
    open var theme : Theme! {
        didSet {
            themeChanged?(theme)
        }
    }

    // This block will be called every time the theme changes.
    open var themeChanged : ((Theme) -> Void)?

    // When `true`, forces highlighting to finish even if illegal syntax is detected.
    open var ignoreIllegals = false

    // MARK: Private Properties

    private let hljs: JSValue
    private let bundle: Bundle
    private let htmlStart: String = "<"
    private let spanStart: String = "span class=\""
    private let spanStartClose: String = "\">"
    private let spanEnd: String = "/span>"
    private let htmlEscape: NSRegularExpression = try! NSRegularExpression(pattern: "&#?[a-zA-Z0-9]+?;", options: .caseInsensitive)


    // MARK:- Constructor

    public init?() {

        /*
         * Default init method.
         *
         * - parameter highlightPath: The path to 'highlight.min.js'. Default: 'Highlighter.framework/highlight.min.js'
         *
         * - returns: Highlightr instance.
         */

        let context = JSContext.init()!

        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Highlighter.self)
        #endif

        self.bundle = bundle

        guard let highlightPath: String = bundle.path(forResource: "highlight.min", ofType: "js") else {
            return nil
        }

        let highlightJs: String = try! String.init(contentsOfFile: highlightPath)
        let _ = context.evaluateScript(highlightJs)

        guard let hljs = context.globalObject.objectForKeyedSubscript("hljs") else {
            return nil
        }

        self.hljs = hljs

        guard setTheme("default") else {
            return nil
        }
    }

    open func highlight(_ code: String, as languageName: String? = nil, fastRender: Bool = true) -> NSAttributedString? {

        /*
         * Takes a String and returns a NSAttributedString with the given language highlighted.
         *
         * - parameter code:           Code to highlight.
         * - parameter languageName:   Language name or alias. Set to `nil` to use auto detection.
         * - parameter fastRender:     Defaults to true - When *true* will use the custom made html parser rather than Apple's solution.
         *
         * - returns: NSAttributedString with the detected code highlighted.
         */

        let returnValue: JSValue
        if let language = languageName {
            let options: [String: Any] = ["language": language, "ignoreIllegals": self.ignoreIllegals]
            returnValue = hljs.invokeMethod("highlight", withArguments: [code, options])
        } else {
            // Use language auto detection
            returnValue = hljs.invokeMethod("highlightAuto", withArguments: [code])
        }

        let renderedHTMLValue: JSValue? = returnValue.objectForKeyedSubscript("value")
        guard var renderedHTMLString: String = renderedHTMLValue!.toString() else {
            return nil
        }

        var returnAttrString: NSAttributedString?

        if (fastRender) {
            returnAttrString = processHTMLString(renderedHTMLString)!
        } else {
            renderedHTMLString = "<style>" + self.theme.lightTheme + "</style><pre><code class=\"hljs\">" + renderedHTMLString + "</code></pre>"
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            let data = renderedHTMLString.data(using: String.Encoding.utf8)!

            safeMainSync
            {
                returnAttrString = try? NSMutableAttributedString(data:data, options: options, documentAttributes:nil)
            }
        }

        return returnAttrString
    }


    // MARK:- Utility Functions

    @discardableResult
    open func setTheme(_ themeName: String) -> Bool {

        /*
         * Set the theme to use for highlighting.
         *
         * - parameter to: Theme name
         *
         * - returns: true if it was possible to set the given theme, false otherwise
         */

        guard let themePath = bundle.path(forResource: themeName + ".min", ofType: "css") else {
            return false
        }

        let themeString = try! String.init(contentsOfFile: themePath)
        self.theme = Theme.init(withTheme: themeString)
        return true
    }

    open func availableThemes() -> [String] {

        /*
         * Returns a list of all the available themes.
         *
         * - returns: Array of Strings
         */

        let paths = bundle.paths(forResourcesOfType: "css", inDirectory: nil) as [NSString]
        var result = [String]()
        for path in paths {
            result.append(path.lastPathComponent.replacingOccurrences(of: ".min.css", with: ""))
        }

        return result
    }

    open func supportedLanguages() -> [String] {

        /*
         * Returns a list of all supported languages.
         *
         * - returns: Array of Strings
         */

        let res: JSValue? = hljs.invokeMethod("listLanguages", withArguments: [])
        return res!.toArray() as! [String]
    }

    private func safeMainSync(_ block: @escaping ()->()) {

        /*
         * Execute the provided block in the main thread synchronously.
         */

        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync {
                block()
            }
        }
    }


    // MARK:- HTML Rendering Functions

    private func processHTMLString(_ string: String) -> NSAttributedString? {

        let scanner: Scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        var scannedString: NSString?
        let resultString: NSMutableAttributedString = NSMutableAttributedString(string: "")
        var propStack = ["hljs"]

        while !scanner.isAtEnd {
            var ended: Bool = false
            if scanner.scanUpTo(htmlStart, into: &scannedString) {
                ended = scanner.isAtEnd
            }

            if scannedString != nil && scannedString!.length > 0 {
                let attrScannedString: NSAttributedString = theme.applyStyleToString(scannedString! as String,
                                                                                     styleList: propStack)
                resultString.append(attrScannedString)

                if ended {
                    continue
                }
            }

            scanner.scanLocation += 1

            let string: NSString = scanner.string as NSString
            let nextChar: String = string.substring(with: NSMakeRange(scanner.scanLocation, 1))
            if nextChar == "s" {
                scanner.scanLocation += (spanStart as NSString).length
                scanner.scanUpTo(spanStartClose, into:&scannedString)
                scanner.scanLocation += (spanStartClose as NSString).length
                propStack.append(scannedString! as String)
            } else if nextChar == "/" {
                scanner.scanLocation += (spanEnd as NSString).length
                propStack.removeLast()
            } else {
                let attrScannedString: NSAttributedString = theme.applyStyleToString("<", styleList: propStack)
                resultString.append(attrScannedString)
                scanner.scanLocation += 1
            }

            scannedString = nil
        }

        let results: [NSTextCheckingResult] = htmlEscape.matches(in: resultString.string,
                                                                 options: [.reportCompletion],
                                                                 range: NSMakeRange(0, resultString.length))
        var localOffset: Int = 0
        for result: NSTextCheckingResult in results {
            let fixedRange: NSRange = NSMakeRange(result.range.location - localOffset, result.range.length)
            let entity: String = (resultString.string as NSString).substring(with: fixedRange)
            if let decodedEntity = HTMLUtils.decode(entity) {
                resultString.replaceCharacters(in: fixedRange, with: String(decodedEntity))
                localOffset += (result.range.length - 1);
            }
        }

        return resultString
    }

}
