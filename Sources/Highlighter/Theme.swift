/*
 *  Highlighter.swift
 *  Copyright 2021, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */


import Foundation


#if os(iOS) || os(tvOS)
    import UIKit
    public typealias HRColor = UIColor
    public typealias HRFont  = UIFont
#else
    import AppKit
    public typealias HRColor = NSColor
    public typealias HRFont  = NSFont
#endif

private typealias HRThemeDict       = [String: [AnyHashable: AnyObject]]
private typealias HRThemeStringDict = [String: [String: String]]


open class Theme {

    /*
     * Theme parser, can be used to configure the theme parameters
     */

    internal let theme: String
    internal var lightTheme: String!

    // MARK: Public Properties
    open var codeFont: HRFont!
    open var boldCodeFont: HRFont!
    open var italicCodeFont: HRFont!
    open var themeBackgroundColour: HRColor!

    
    // MARK: Private Properties
    private var themeDict : HRThemeDict!
    private var strippedTheme : HRThemeStringDict!


    init(withTheme: String = "default", usingFont: HRFont? = nil) {
        
        // Record the theme name
        self.theme = withTheme
        
        // Apply the font choice
        if let font: HRFont = usingFont {
            setCodeFont(font)
        } else {
            setCodeFont(HRFont(name: "courier", size: 14)!)
        }

        // Generate and store theme variants
        self.strippedTheme = stripTheme(self.theme)
        self.lightTheme = strippedThemeToString(self.strippedTheme)
        self.themeDict = strippedThemeToTheme(self.strippedTheme)

        // Determine the theme's background colour as a hex string
        var backgroundColourHex: String? = self.strippedTheme[".hljs"]?["background"]
        if backgroundColourHex == nil {
            backgroundColourHex = self.strippedTheme[".hljs"]?["background-color"]
        }
        
        // Convert the hex to a UIColor or NSColor
        if let bgColourHex = backgroundColourHex {
            if (bgColourHex == "white") {
                self.themeBackgroundColour = HRColor(white: 1, alpha: 1)
            } else if (bgColourHex == "black") {
                self.themeBackgroundColour = HRColor(white: 0, alpha: 1)
            } else {
                let range: Range? = bgColourHex.range(of: "#")
                let hexString: String = String(bgColourHex[(range?.lowerBound)!...])
                self.themeBackgroundColour = colourFromHexString(hexString)
            }
        } else {
            // Set a generic (light) background
            self.themeBackgroundColour = HRColor.white
        }
    }

    
    open func setCodeFont(_ font: HRFont) {

        /*
         * Changes the theme font. This will try to automatically populate the codeFont,
         * boldCodeFont and italicCodeFont properties based on the provided font.
         *
         * - parameter font: UIFont (iOS or tvOS) or NSFont (OSX)
        */

        self.codeFont = font

        #if os(iOS) || os(tvOS)
        let boldDescriptor    = UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.family:font.familyName,
                                                                  UIFontDescriptor.AttributeName.face:"Bold"])
        let italicDescriptor  = UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.family:font.familyName,
                                                                  UIFontDescriptor.AttributeName.face:"Italic"])
        let obliqueDescriptor = UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.family:font.familyName,
                                                                  UIFontDescriptor.AttributeName.face:"Oblique"])
        #else
        let boldDescriptor    = NSFontDescriptor(fontAttributes: [.family:font.familyName!,
                                                                  .face:"Bold"])
        let italicDescriptor  = NSFontDescriptor(fontAttributes: [.family:font.familyName!,
                                                                  .face:"Italic"])
        let obliqueDescriptor = NSFontDescriptor(fontAttributes: [.family:font.familyName!,
                                                                  .face:"Oblique"])
        #endif

        self.boldCodeFont   = HRFont(descriptor: boldDescriptor, size: font.pointSize)
        self.italicCodeFont = HRFont(descriptor: italicDescriptor, size: font.pointSize)

        if (self.italicCodeFont == nil || self.italicCodeFont.familyName != font.familyName) {
            self.italicCodeFont = HRFont(descriptor: obliqueDescriptor, size: font.pointSize)
        }

        if (self.italicCodeFont == nil) {
            self.italicCodeFont = font
        }

        if (self.boldCodeFont == nil) {
            self.boldCodeFont = font
        }

        if (self.themeDict != nil) {
            self.themeDict = strippedThemeToTheme(self.strippedTheme)
        }
    }

    
    internal func applyStyleToString(_ string: String, styleList: [String]) -> NSAttributedString {
        
        /*
         * Convert a String to an NSAttributedString by applying the specified attributes.
         * Automatically sets the font according to the theme's stored font
         *
         * - parameter string:    The base string
         * - parameter styleList: An array of attribute values
         *
         * - returns: NSAttributedString
         */
        
        let returnString: NSAttributedString

        if styleList.count > 0 {
            // Build the attributes from the style list, including the font
            var attrs = [AttributedStringKey: Any]()
            attrs[.font] = self.codeFont
            for style in styleList {
                if let themeStyle = themeDict[style] as? [AttributedStringKey: Any] {
                    for (attrName, attrValue) in themeStyle {
                        attrs.updateValue(attrValue, forKey: attrName)
                    }
                }
            }

            returnString = NSAttributedString(string: string, attributes:attrs)
        } else {
			// No specified attributes? Just set the font
            returnString = NSAttributedString(string: string, attributes:[AttributedStringKey.font:codeFont as Any])
        }

        return returnString
    }

    
    private func stripTheme(_ themeString : String) -> HRThemeStringDict {
        
        /*
         * Decode the theme CSS into a dictionary
         *
         * - parameter themeString: The loaded theme CSS
         *
         * - returns: the theme dictionary
         */
        
        let objcString: NSString = (themeString as NSString)
        let cssRegex = try! NSRegularExpression(pattern: "(?:(\\.[a-zA-Z0-9\\-_]*(?:[, ]\\.[a-zA-Z0-9\\-_]*)*)\\{([^\\}]*?)\\})", options:[.caseInsensitive])
        let results = cssRegex.matches(in: themeString, options: [.reportCompletion], range: NSMakeRange(0, objcString.length))
        var resultDict = [String: [String: String]]()

        for result in results {
            if result.numberOfRanges == 3 {
                var attributes = [String: String]()
                let cssPairs = objcString.substring(with: result.range(at: 2)).components(separatedBy: ";")
                for pair in cssPairs {
                    let cssPropComp = pair.components(separatedBy: ":")
                    if (cssPropComp.count == 2) {
                        attributes[cssPropComp[0]] = cssPropComp[1]
                    }
                }

                if attributes.count > 0 {
                    resultDict[objcString.substring(with: result.range(at: 1))] = attributes
                }
            }
        }

        var returnDict = [String: [String: String]]()
        for (keys,result) in resultDict {
            let keyArray = keys.replacingOccurrences(of: " ", with: ",").components(separatedBy: ",")
            for key in keyArray {
                var props : [String: String]?
                props = returnDict[key]
                if props == nil {
                    props = [String:String]()
                }

                for (pName, pValue) in result {
                    props!.updateValue(pValue, forKey: pName)
                }

                returnDict[key] = props!
            }
        }

        return returnDict
    }

    
    private func strippedThemeToString(_ themeDict: HRThemeStringDict) -> String {

        /*
         * Recode a theme dictionary to a String
         *
         * - parameter themeDict: The theme dictionary
         *
         * - returns: the theme as a string
         */
        
        var resultString: String = ""
        for (key, props) in themeDict {
            resultString += (key + "{")
            for (cssProp, val) in props {
                if key != ".hljs" || (cssProp.lowercased() != "background-color" && cssProp.lowercased() != "background") {
                    resultString += "\(cssProp):\(val);"
                }
            }

            resultString += "}"
        }

        return resultString
    }

    
    private func strippedThemeToTheme(_ themeStringDict: HRThemeStringDict) -> HRThemeDict {

        /*
         * Convert between one type of theme dictionary and another
         *
         * - parameter themeStringDict: The loaded theme CSS
         *
         * - returns: The theme dictionary
         */
        
        var returnTheme = HRThemeDict()
        for (className, props) in themeStringDict {
            var keyProps = [AttributedStringKey: AnyObject]()
            for (key, prop) in props {
                switch key {
                case "color":
                    keyProps[attributeForCSSKey(key)] = colourFromHexString(prop)
                case "font-style":
                    keyProps[attributeForCSSKey(key)] = fontForCSSStyle(prop)
                case "font-weight":
                    keyProps[attributeForCSSKey(key)] = fontForCSSStyle(prop)
                case "background-color":
                    keyProps[attributeForCSSKey(key)] = colourFromHexString(prop)
                default:
                    break
                }
            }

            if keyProps.count > 0 {
                let key: String = className.replacingOccurrences(of: ".", with: "")
                returnTheme[key] = keyProps
            }
        }

        return returnTheme
    }

    
    private func fontForCSSStyle(_ fontStyle: String) -> HRFont {
        
        /*
         * Get font information from a CSS string and return a suitable
         * UIFont or NSFont object -- which we have already set up,
         * see setCodeFont()
         *
         * - parameter fontStyle: The CSS font information
         *
         * - returns: The font object
         */
        
        switch fontStyle {
            case "bold", "bolder", "600", "700", "800", "900":
                return self.boldCodeFont
            case "italic", "oblique":
                return self.italicCodeFont
            default:
                return self.codeFont
        }
    }

    
    private func attributeForCSSKey(_ key: String) -> AttributedStringKey {

        /*
         * Emit an AttributedString key based on the a style key from a CSS file.
         *
         * - parameter key: The CSS style key
         *
         * - returns: The AttributedString key
         */
        
        switch key {
        case "color":
            return .foregroundColor
        case "font-weight":
            return .font
        case "font-style":
            return .font
        case "background-color":
            return .backgroundColor
        default:
            return .font
        }
    }

    private func colourFromHexString(_ colourValue: String) -> HRColor {

        /*
         * Emit an UIColor or NSColor to match a hex string or le.
         *
         * - parameter colourValue: A CSS colour value, either a literal or a hex string
         *
         * - returns: The colour object
         */
        
        var colourString: String = colourValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            // The colour is defined by a hex value
            colourString = (colourString as NSString).substring(from: 1)
        } else {
            switch colourString {
            case "white":
                return HRColor.init(white: 1.0, alpha: 1.0)
            case "black":
                return HRColor.init(white: 0.0, alpha: 1.0)
            case "red":
                return HRColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            case "green":
                return HRColor.init(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
            case "blue":
                return HRColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
            case "navy":
                return HRColor.init(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0)
            default:
                return HRColor.gray
            }
        }
        
        // Colours in hex strings have 3, 6 or 8 (6 + alpha) values
        if colourString.count != 8 || colourString.count != 6 && colourString.count != 3 {
            return HRColor.gray
        }

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 0
        var divisor: CGFloat
        var alpha: CGFloat = 1.0

        if colourString.count == 6 || colourString.count == 8 {
            // Decode a six-character hex string
            let rString: String = (colourString as NSString).substring(to: 2)
            let gString: String = ((colourString as NSString).substring(from: 2) as NSString).substring(to: 2)
            let bString: String = ((colourString as NSString).substring(from: 4) as NSString).substring(to: 2)

            Scanner(string: rString).scanHexInt64(&r)
            Scanner(string: gString).scanHexInt64(&g)
            Scanner(string: bString).scanHexInt64(&b)

            divisor = 255.0
            
            if colourString.count == 8 {
                // Decode the eight-character hex string's alpha value
                let aString: String = ((colourString as NSString).substring(from: 6) as NSString).substring(to: 2)
                Scanner(string: aString).scanHexInt64(&a)
                alpha = CGFloat(a) / divisor
            }
        } else {
            // Decode a three-character hex string
            let rString: String = (colourString as NSString).substring(to: 1)
            let gString: String = ((colourString as NSString).substring(from: 1) as NSString).substring(to: 1)
            let bString: String = ((colourString as NSString).substring(from: 2) as NSString).substring(to: 1)

            Scanner(string: rString).scanHexInt64(&r)
            Scanner(string: gString).scanHexInt64(&g)
            Scanner(string: bString).scanHexInt64(&b)

            divisor = 15.0
        }

        return HRColor(red: CGFloat(r) / divisor, green: CGFloat(g) / divisor, blue: CGFloat(b) / divisor, alpha: alpha)
    }
}
