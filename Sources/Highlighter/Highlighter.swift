/*
 *  Highlighter.swift
 *  Copyright 2021, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */


import Foundation
import JavaScriptCore

#if os(OSX)
import AppKit
#endif


/**
    Wrapper class for generating a highlighted NSAttributedString from a code string.
 */
open class Highlighter {

    // MARK:- Public Properties
    open var theme: Theme! {
        didSet {
            themeChanged?(theme)
        }
    }

    // This block will be called every time the theme changes.
    open var themeChanged: ((Theme) -> Void)?

    // When `true`, forces highlighting to finish even if illegal syntax is detected.
    open var ignoreIllegals = false

    
    // MARK:- Private Properties
    private let hljs: JSValue
    private let bundle: Bundle
    private let htmlStart: String = "<"
    private let spanStart: String = "span class=\""
    private let spanStartClose: String = "\">"
    private let spanEnd: String = "/span>"
    private let htmlEscape: NSRegularExpression = try! NSRegularExpression(pattern: "&#?[a-zA-Z0-9]+?;", options: .caseInsensitive)


    // MARK:- Constructor
    
    /**
     The default initialiser.
     
     Returns `nil` on failure to load or evaluate `highlight.min.js`,
     or to load the default theme (`Default`)
    */
    public init?() {
        
        // Get the library's bundle based on how it's
        // being included in the host app
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Highlighter.self)
        #endif

        // Load the highlight.js code from the bundle or fail
        guard let highlightPath: String = bundle.path(forResource: "highlight.min", ofType: "js") else {
            return nil
        }

        // Check the JavaScript or fail
        let context = JSContext.init()!
        let highlightJs: String = try! String.init(contentsOfFile: highlightPath)
        let _ = context.evaluateScript(highlightJs)
        guard let hljs = context.globalObject.objectForKeyedSubscript("hljs") else {
            return nil
        }
        
        // Store the results for later
        self.hljs = hljs
        self.bundle = bundle
        
        // Check and set applying a theme or fail
        // NOTE 'setTheme()' depends on 'self.bundle'
        guard setTheme("default") else {
            return nil
        }
    }

    
    //MARK: - Primary Functions
    
    /**
    Highlight the supplied code in the specified language.
    
    - Parameters:
     - code:         The source code to highlight.
     - languageName: The language in which the code is written.
     - doFastRender: Should fast rendering be used? Default: `true`.
     
     - Returns: The highlighted code as an NSAttributedString, or `nil`
    */
    open func highlight(_ code: String, as languageName: String? = nil, doFastRender: Bool = true) -> NSAttributedString? {

        let returnValue: JSValue
        
        if let language = languageName {
            // Use the specified language
            // NOTE Will return 'undefined' (trapped below) if it's a unknown language
            let options: [String: Any] = ["language": language, "ignoreIllegals": self.ignoreIllegals]
            returnValue = hljs.invokeMethod("highlight",
                                            withArguments: [code, options])
        } else {
            // Use language auto detection
            returnValue = hljs.invokeMethod("highlightAuto",
                                            withArguments: [code])
        }
        
        // Check we got a valid string back - fail if we didn't
        let renderedHTMLValue: JSValue? = returnValue.objectForKeyedSubscript("value")
        guard var renderedHTMLString: String = renderedHTMLValue!.toString() else {
            return nil
        }
        
        // Trap 'undefined' output as this is effectively an error condition
        // and should not be returned as a valid result -- it's actually a fail
        if renderedHTMLString == "undefined" {
            return nil
        }

        // Convert the HTML received from Highlight.js to an NSAttributedString or nil
        var returnAttrString: NSAttributedString? = nil
        
        if doFastRender {
            // Use fast rendering -- the default
            returnAttrString = processHTMLString(renderedHTMLString)!
        } else {
            // Use NSAttributedString's own not-so-fast rendering
            renderedHTMLString = "<style>" + self.theme.lightTheme + "</style><pre><code class=\"hljs\">" + renderedHTMLString + "</code></pre>"
            
            let data = renderedHTMLString.data(using: String.Encoding.utf8)!
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            // Execute on main thread
            // NOTE Not sure why, when we don't do this elsewhere
            safeMainSync
            {
                returnAttrString = try? NSMutableAttributedString(data:data, options: options, documentAttributes:nil)
            }
        }

        return returnAttrString
    }


    /**
     Set the Highligt.js theme to use for highlighting.
    
     - Parameters:
        - themeName: The Highlight.js theme's name.
        - withFont:  The name of the font to use. Default: Courier.
        - ofSize:    The size of the font. Default: 14pt.
     
     - Returns: Whether the theme was successfully applied (`true`) or not (`false`)
    */
    @discardableResult
    open func setTheme(_ themeName: String, withFont: String? = nil, ofSize: CGFloat? = nil) -> Bool {
        
        // Make sure we can load the theme's CSS file -- or fail
        guard let themePath = self.bundle.path(forResource: themeName, ofType: "css") else {
            return false
        }
        
        // Create the required font
        // If this fails ('font' == nil), we use the defaults
        var font: HRFont? = nil
        if let fontName: String = withFont {
            var size: CGFloat = 14.0
            if ofSize != nil {
                size = ofSize!
            }
            
            font = HRFont.init(name: fontName, size: size)
        }
        
        // Get the theme CSS and instantiate a Theme object
        let themeString = try! String.init(contentsOfFile: themePath)
        self.theme = Theme.init(withTheme: themeString, usingFont: font)
        return true
    }

    
    /**
     Get a list of available Highlight.js themes.
     
     Just lists what CSS files are in the bundle.
    
     - Returns: The list of themes as an array of strings.
    */
    open func availableThemes() -> [String] {

        let paths = bundle.paths(forResourcesOfType: "css", inDirectory: nil) as [NSString]
        var result = [String]()
        for path in paths {
            result.append(path.lastPathComponent.replacingOccurrences(of: ".css", with: ""))
        }

        return result
    }

    
    /**
     Get a list of languages supported by Highlight.js.
    
     - Returns: The list of languages as an array of strings.
    */
    open func supportedLanguages() -> [String] {

        let res: JSValue? = hljs.invokeMethod("listLanguages", withArguments: [])
        return res!.toArray() as! [String]
    }

    
    // MARK:- Fast HTML Rendering Function

    /**
     Generate an NSAttributedString from HTML source.
    
     - Parameters:
        - htmlString: The HTML to be converted.
     
     - Returns: The rendered HTML as an NSAttibutedString, or `nil` if an error occurred.
    */
    private func processHTMLString(_ htmlString: String) -> NSAttributedString? {

        let scanner: Scanner = Scanner(string: htmlString)
        scanner.charactersToBeSkipped = nil
        var scannedString: NSString?
        let resultString: NSMutableAttributedString = NSMutableAttributedString(string: "")
        var propStack: [String] = ["hljs"]

        while !scanner.isAtEnd {
            var ended: Bool = false
            if scanner.scanUpTo(self.htmlStart,
                                into: &scannedString) {
                ended = scanner.isAtEnd
            }

            if scannedString != nil && scannedString!.length > 0 {
                let attrScannedString: NSAttributedString = self.theme.applyStyleToString(scannedString! as String,
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
                scanner.scanLocation += (self.spanStart as NSString).length
                scanner.scanUpTo(self.spanStartClose, into:&scannedString)
                scanner.scanLocation += (self.spanStartClose as NSString).length
                propStack.append(scannedString! as String)
            } else if nextChar == "/" {
                scanner.scanLocation += (self.spanEnd as NSString).length
                propStack.removeLast()
            } else {
                let attrScannedString: NSAttributedString = self.theme.applyStyleToString("<", styleList: propStack)
                resultString.append(attrScannedString)
                scanner.scanLocation += 1
            }

            scannedString = nil
        }

        let results: [NSTextCheckingResult] = self.htmlEscape.matches(in: resultString.string,
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
    
    
    // MARK:- Utility Functions

    /**
     Execute the supplied block on the main thread.
    */
    private func safeMainSync(_ block: @escaping ()->()) {

        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync {
                block()
            }
        }
    }


    
}
