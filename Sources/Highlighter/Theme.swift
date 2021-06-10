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


/**
 Class representing HighlightSwift's interal storage of a processed Highlight.js theme.
 */
open class Theme {

    // MARK:- Public Properties
    internal let theme: String
    internal var lightTheme: String!

    open var codeFont: HRFont!
    open var boldCodeFont: HRFont!
    open var italicCodeFont: HRFont!
    open var themeBackgroundColour: HRColor!

    
    // MARK:- Private Properties
    private var themeDict : HRThemeDict!
    private var strippedTheme : HRThemeStringDict!


    // MARK:- Constructor
    
    /**
     The default initialiser.
     
     - Parameters:
        - withTheme: The name of the Highlight.js theme to use. Default: `Default`.
        - usingFont: Optionally, a UIFont or NSFont to apply to the theme. Default: Courier @ 14pt.
    */
    init(withTheme: String = "default", usingFont: HRFont? = nil) {
        
        // Record the theme name
        self.theme = withTheme
        
        // Apply the font choice
        if let font: HRFont = usingFont {
            setCodeFont(font)
        } else if let font = HRFont(name: "courier", size: 14.0) {
            setCodeFont(font)
        } else {
            // Just in case Courier has been deleted...
            setCodeFont(HRFont.systemFont(ofSize: 14.0))
        }

        // Generate and store the theme variants
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
            self.themeBackgroundColour = colourFromHexString(bgColourHex)
        } else {
            // Set a generic (light) background
            self.themeBackgroundColour = HRColor.white
        }
    }

    
    // MARK:- Getters and Setters
    
    /**
     Change the theme's font.
     
     This will automatically populate bold and italic variants of the specified font.
    
     - Parameters:
        - font: The UIFont or NSFont to use.
    */
    open func setCodeFont(_ font: HRFont) {

        // Store the primary font choice
        self.codeFont = font
        
        // Generate the bold and italic variants
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

    
    // MARK:- Private Functions
    
    /**
     Convert a string to an NSAttributedString styled using the theme.
        
     Automatically applies the theme's font.
    
     - Parameters:
        - string:    The source code string.
        - styleList: An array of attribute keys (strings).
     
     - Returns: The styled text as an NSAttributedString.
    */
    internal func applyStyleToString(_ string: String, styleList: [String]) -> NSAttributedString {
        
        let returnString: NSAttributedString

        if styleList.count > 0 {
            // Build the attributes from the style list, including the font
            var attrs = [AttributedStringKey: Any]()
            attrs[.font] = self.codeFont
            for style in styleList {
                if let themeStyle = self.themeDict[style] as? [AttributedStringKey: Any] {
                    for (attrName, attrValue) in themeStyle {
                        attrs.updateValue(attrValue, forKey: attrName)
                    }
                }
            }

            returnString = NSAttributedString(string: string, attributes:attrs)
        } else {
            // No specified attributes? Just set the font
            returnString = NSAttributedString(string: string, attributes:[AttributedStringKey.font: codeFont as Any])
        }

        return returnString
    }

    /**
     Convert a Highlight.js theme's CSS to the class' string dictionary.
        
     - Parameters:
        - themeString: The theme's CSS string.
     
     - Returns: A dictionary of styles and values.
    */
    private func stripTheme(_ themeString : String) -> HRThemeStringDict {
        
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

    
    /**
     Convert an instance's string dictionary to a CSS string.
        
     - Parameters:
        - themeStringDict: The dictionary of styles and values.
     
     - Returns: CSS code as a string.
    */
    private func strippedThemeToString(_ themeStringDict: HRThemeStringDict) -> String {

        var resultString: String = ""
        for (key, props) in themeStringDict {
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

    
    /**
     Convert  in instance's string dictionary to base dictionary.
        
     - Parameters:
        - themeStringDict: The dictionary of styles and values.
     
     - Returns: The base dictionary.
    */
    private func strippedThemeToTheme(_ themeStringDict: HRThemeStringDict) -> HRThemeDict {

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

    
    /**
     Get font information from a CSS string and use it to generate a font object.
        
     - Parameters:
        - fontStyle: The CSS font definition.
     
     - Returns: A UIFont or NSFont.
    */
    internal func fontForCSSStyle(_ fontStyle: String) -> HRFont {
        
        switch fontStyle {
            case "bold", "bolder", "600", "700", "800", "900":
                return self.boldCodeFont
            case "italic", "oblique":
                return self.italicCodeFont
            default:
                return self.codeFont
        }
    }

    
    /**
     Emit an AttributedString key based on the a style key from a CSS file.
        
     - Parameters:
        - key: The CSS attribute key.
     
     - Returns: The NSAttributedString key.
    */
    internal func attributeForCSSKey(_ key: String) -> AttributedStringKey {

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

    /**
     Emit a colour object to match a hex string or CSS colour identifiier.
     
     Identifiers supported:
     
     * `white`
     * `black`
     * `red`
     * `green`
     * `blue`
     * `navy`
     
     Unknown colour identifiers default to grey.
        
     - Parameters:
        - colourValue: The CSS colour specification.
     
     - Returns: A UIColor or NSColor.
    */
    internal func colourFromHexString(_ colourValue: String) -> HRColor {
        
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
        if colourString.count != 8 && colourString.count != 6 && colourString.count != 3 {
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
