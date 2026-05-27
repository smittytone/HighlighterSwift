/*
 *  Highlighter.swift
 *  Copyright 2026, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif


/**
 Typealiases
 */
private typealias HRThemeDict       = [String: [AnyHashable: AnyObject]]
private typealias HRThemeStringDict = [String: [String: String]]


/**
 Class representing HighlightSwift's interal storage of a processed Highlight.js theme.
 */
public class Theme {

    // MARK: - Public Properties

    public var codeFont: HRFont!
    public var boldCodeFont: HRFont!
    public var italicCodeFont: HRFont!
    public var themeBackgroundColour: HRColor!
    // FROM 1.1.3
    public var lineSpacing: CGFloat = 0.0
    public var paraSpacing: CGFloat = 0.0
    // FROM 1.2.0
    public var isDark: Bool = false
    public var fontSize: CGFloat = 18.0
    // FROM 3.1.0
    public var name: String = ""


    // MARK: - Private Properties

    private  var themeDict : HRThemeDict!
    private  var strippedTheme : HRThemeStringDict!
    internal let theme: String
    internal var lightTheme: String!


    // MARK: - Constructor

    /**
     The default initialiser.
     
     - Parameters:
        - withTheme: The name of the Highlight.js theme to use. Default: `Default`.
        - usingFont: Optionally, a UIFont or NSFont to apply to the theme. Default: Courier @ 14pt.
    */
    init(withTheme: String = "default", usingFont: HRFont? = nil) {
        
        // Record the theme name
        self.name = withTheme
        self.theme = withTheme      // This SHOULD be the CSS...

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


    // MARK: - Getters and Setters

    /**
     Change the theme's font.
     
     This will automatically populate bold and italic variants of the specified font.
    
     - Parameters:
        - font: The UIFont or NSFont to use.
    */
    public func setCodeFont(_ font: HRFont) {

        // Store the primary font choice
        self.codeFont = font
        // FROM 1.2.0
        self.fontSize = font.pointSize

        // Generate the bold and italic variants
#if os(OSX)
        let boldDescriptor    = NSFontDescriptor(fontAttributes: [.family:font.familyName!,
                                                                  .face:"Bold"])
        let italicDescriptor  = NSFontDescriptor(fontAttributes: [.family:font.familyName!,
                                                                  .face:"Italic"])
        let obliqueDescriptor = NSFontDescriptor(fontAttributes: [.family:font.familyName!,
                                                                  .face:"Oblique"])
#else
        let boldDescriptor    = UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.family:font.familyName,
                                                                  UIFontDescriptor.AttributeName.face:"Bold"])
        let italicDescriptor  = UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.family:font.familyName,
                                                                  UIFontDescriptor.AttributeName.face:"Italic"])
        let obliqueDescriptor = UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.family:font.familyName,
                                                                  UIFontDescriptor.AttributeName.face:"Oblique"])
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


    // MARK: - Private Functions

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
        
        // FROM 1.1.3
        // Incorporate line and paragraph spacing
        let spacedParaStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        spacedParaStyle.lineSpacing = (self.lineSpacing >= 0.0 ? self.lineSpacing : 0.0)
        spacedParaStyle.paragraphSpacing = (self.paraSpacing >= 0.0 ? self.paraSpacing : 0.0)
        
        if styleList.count > 0 {
            // Build the attributes from the style list, including the font
            var embeddedAlpha: HRColor? = nil
            var attrs = [AttributedStringKey: Any]()
            attrs[.font] = self.codeFont
            attrs[.paragraphStyle] = spacedParaStyle
            for style in styleList {
                // FROM 3.1.0
                // Highlight.js once listed styles as, for example, `hljs-title`.
                // Now you may see `hljs-title class_ inherited__`.
                // The CSS is `.hljs-title.class_.inherited__`
                // The extra items should be parsed and handled, but for now, just remove them.
                let aStyle: String
                if let spaceIndex = style.firstIndex(of: " ") {
                    aStyle = String(style[style.startIndex..<spaceIndex])
                } else {
                    aStyle = style
                }

                // Add the style to the current attribute list, if one exists
                if let themeStyle = self.themeDict[aStyle] as? [AttributedStringKey: Any] {
                    for (attrName, attrValue) in themeStyle {
                        // FROM 3.1.0
                        // Trap a covert opacity value
                        if attrName == .strokeColor {
                            embeddedAlpha = attrValue as? HRColor
                            continue
                        }

                        attrs.updateValue(attrValue, forKey: attrName)
                    }
                } else {
#if DEBUG
                    print("WARNING MISSING STYLE in \(self.name): \(aStyle)")
#endif
                }
            }

            // FROM 3.1.0
            // Apply an embedded alpha value, if there is one
            if let alpha = embeddedAlpha {
                // There has been an opacity setting, so merge it into the current foreground
                var base: HRColor = .labelColor
                if attrs[.foregroundColor] != nil {
                    base = attrs[.foregroundColor]! as! HRColor
                }

                attrs[.foregroundColor] = base.withAlphaComponent(alpha.alphaComponent)
            }

            returnString = NSAttributedString(string: string, attributes:attrs)
        } else {
            // No specified attributes? Just set the font
            returnString = NSAttributedString(string: string,
                                              attributes:[.font: self.codeFont as Any,
                                                          .paragraphStyle: spacedParaStyle])
        }

        return returnString
    }


    /**
     Convert a Highlight.js theme's CSS to the class' string dictionary.
        
     - Parameters:
        - css: The theme's CSS string.

     - Returns: A dictionary of styles and values.
    */
    private func stripTheme(_ css: String) -> HRThemeStringDict {

        var resultDict = [String: [String: String]]()
        var returnDict = [String: [String: String]]()

        // Use a regex to find comma-separated sequences of style names followed by format instructions (within braces)
        // and use the sequence as keys in a dictionary -- the values are the formatting pairs in arrays
        // FROM 3.1.0
        // Use a new regex for our minfied style CSS files, and a more Swifty approach
        let cssRegex = try! NSRegularExpression(pattern: #"(?:/\*[\s\S]*?\*/\s*|([^{}]+?)\s*\{([^}]*)\})"#)
        cssRegex.enumerateMatches(in: css, range: NSRange(css.startIndex..., in: css)) { match, _, _ in
            // guard returns nil ranges on comment matches, so those are silently skipped
            guard let match,
                  let nameListRange = Range(match.range(at: 1), in: css),
                  let formatListRange = Range(match.range(at: 2), in: css) else { return }
            let nameList = String(css[nameListRange])
            let formatList = String(css[formatListRange])

            // Separate out the format section's elements into an array of pairs
            var attributes = [String:String]()
            let formatPairs = formatList.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ";")
            for formatPair in formatPairs {
                let formatParts = formatPair.components(separatedBy: ":")
                if (formatParts.count == 2) {
                    attributes[formatParts[0]] = formatParts[1]
                }
            }

            // We have some format data to store
            if attributes.count > 0 {
                // Check if we're adding attributes to an existing hljs key
                if resultDict[nameList] != nil {
                    // We have the key already so merge in the latest attribute dictionary
                    let existingAttributes: [String: String] = resultDict[nameList]!
                    resultDict[nameList] = existingAttributes.merging(attributes, uniquingKeysWith: { (first, _) in first } )
                } else {
                    // Set the attributes to a new key
                    resultDict[nameList] = attributes
                }
            }
        }

        // Now generate a new dictionary with the individual style names as keys
        // and each one's format array as a value
        for (keys, result) in resultDict {
            let keyArray = keys.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ",") // .replacingOccurrences(of: " ", with: ",")
            for key in keyArray {
                var properties = [String: String]()
                if returnDict[key] != nil {
                    properties = returnDict[key]!
                }

                for (propName, propValue) in result {
                    properties.updateValue(propValue, forKey: propName)
                }

                returnDict[key] = properties
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
     Convert an instance's string dictionary to base dictionary.

     - Parameters:
        - themeStringDict: The dictionary of styles and values.
     
     - Returns: The base dictionary.
    */
    private func strippedThemeToTheme(_ themeStringDict: HRThemeStringDict) -> HRThemeDict {

        var returnTheme = HRThemeDict()
        for (className, props) in themeStringDict {
            var atttributes = [AttributedStringKey: AnyObject]()
            for (key, prop) in props {
                switch key {
                    case "color":
                        atttributes[attributeForCSSKey(key)] = colourFromHexString(prop)
                    case "font-style":
                        atttributes[attributeForCSSKey(key)] = fontForCSSStyle(prop)
                    case "font-weight":
                        atttributes[attributeForCSSKey(key)] = fontForCSSStyle(prop)
                    case "background-color":
                        atttributes[attributeForCSSKey(key)] = colourFromHexString(prop)
                    // FROM 3.1.0
                    case "opacity":
                        // Make sure the opacity value is convertible and in range,
                        // then store the opacity as an NSColor/UIColor for use in
                        // `applyStyleToString()`
                        var alphaValue = 1.0
                        if let alpha = Double(prop) {
                            alphaValue = alpha
                        }

                        if alphaValue < 0.0 { alphaValue = 0.0 }
                        if alphaValue > 1.0 { alphaValue = 1.0 }
                        atttributes[attributeForCSSKey(key)] = HRColor(red: 0.0, green: 0.0, blue: 0.0, alpha: alphaValue)
                    default:
                        break
                }
            }

            if atttributes.count > 0 {
                let key: String = className.replacingOccurrences(of: ".", with: "")
                returnTheme[key] = atttributes
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
            // FROM 3.1.0
            // Embedded opacity values within `.strokeColor`, which is an
            // `AttributedStringKey` value we don't otherwise support.
            case "opacity":
                return .strokeColor
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
         * `silver`
     
     Unknown colour identifiers default to grey.
        
     - Parameters:
        - colourValue: The CSS colour specification.
     
     - Returns: A UIColor or NSColor.
    */
    internal func colourFromHexString(_ colourValue: String) -> HRColor {
        
        var colourString: String = colourValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            // The colour is defined by a hex value
            colourString = String(colourString.dropFirst(1)) //(colourString as NSString).substring(from: 1)
        } else {
            switch colourString {
                case "red":
                    return .red
                case "green":
                    return .green
                case "blue":
                    return .blue
                case "white":
                    return HRColor(white: 1.0, alpha: 1.0)
                case "black":
                    return HRColor(white: 0.0, alpha: 1.0)
                case "gray":
                    return .hexToColour("AAAAAA")
                case "navy":
                    return .hexToColour("07188D")
                case "silver":
                    return .hexToColour("D6D6D6")
                case "olive":
                    return .hexToColour("929000")
                case "purple":
                    return .hexToColour("942193")
                case "maroon":
                    return .hexToColour("941751")
                default:
                    return .gray
            }
        }
        
        // Colours in hex strings have 3, 6 or 8 (6 + alpha) values
        if colourString.count != 8 && colourString.count != 6 && colourString.count != 3 {
#if DEBUG
            return .red
#else
            return .gray
#endif
        }

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 0
        var divisor: CGFloat
        var alpha: CGFloat = 1.0

        if colourString.count == 6 || colourString.count == 8 {
            // Decode a six-character hex string
            let rString = String(colourString.dropLast(colourString.count - 2))
            let gString = String(colourString.dropFirst(2).dropLast(colourString.count - 4))
            let bString = String(colourString.dropFirst(4).dropLast(colourString.count - 6))

            Scanner(string: rString).scanHexInt64(&r)
            Scanner(string: gString).scanHexInt64(&g)
            Scanner(string: bString).scanHexInt64(&b)

            divisor = 255.0
            
            if colourString.count == 8 {
                // Decode the eight-character hex string's alpha value
                let aString = String(colourString.dropFirst(6))
                Scanner(string: aString).scanHexInt64(&a)
                alpha = CGFloat(a) / divisor
            }
        } else {
            // Decode a three-character hex string
            let rString = String(colourString.dropLast(2))
            let gString = String(colourString.dropFirst(1).dropLast(1))
            let bString = String(colourString.dropFirst(2))

            Scanner(string: rString).scanHexInt64(&r)
            Scanner(string: gString).scanHexInt64(&g)
            Scanner(string: bString).scanHexInt64(&b)

            divisor = 15.0
        }

        return HRColor(red: CGFloat(r) / divisor, green: CGFloat(g) / divisor, blue: CGFloat(b) / divisor, alpha: alpha)
    }
}
