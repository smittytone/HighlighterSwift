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

private typealias HRThemeDict = [String: [AnyHashable: AnyObject]]
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


    init(withTheme: String = "default") {

        self.theme = withTheme
        setCodeFont(HRFont(name: "Courier", size: 14)!)

        self.strippedTheme = stripTheme(withTheme)
        self.lightTheme = strippedThemeToString(self.strippedTheme)
        self.themeDict = strippedThemeToTheme(self.strippedTheme)

        var backgroundColourHex: String? = self.strippedTheme[".hljs"]?["background"]
        if (backgroundColourHex == nil) {
            backgroundColourHex = strippedTheme[".hljs"]?["background-color"]
        }

        if let backgroundColourHex = backgroundColourHex {
            if (backgroundColourHex == "white") {
                self.themeBackgroundColour = HRColor(white: 1, alpha: 1)
            } else if (backgroundColourHex == "black") {
                self.themeBackgroundColour = HRColor(white: 0, alpha: 1)
            } else {
                let range: Range? = backgroundColourHex.range(of: "#")
                let hexString: String = String(backgroundColourHex[(range?.lowerBound)!...])
                self.themeBackgroundColour = colourFromHexString(hexString)
            }
        } else {
            self.themeBackgroundColour = HRColor.white
        }
    }

    open func setCodeFont(_ font: HRFont) {

        /*
         * Changes the theme font. This will try to automatically populate the codeFont,
         * boldCodeFont and italicCodeFont properties based on the provided font.
         *
         * -parameter font: UIFont (iOS or tvOS) or NSFont (OSX)
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

        let returnString: NSAttributedString

        if styleList.count > 0 {
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
			returnString = NSAttributedString(string: string, attributes:[AttributedStringKey.font:codeFont as Any])
        }

        return returnString
    }

    private func stripTheme(_ themeString : String) -> [String:[String:String]] {

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

    private func strippedThemeToString(_ theme: HRThemeStringDict) -> String {

        var resultString: String = ""
        for (key, props) in theme {
            resultString += key+"{"
            for (cssProp, val) in props {
                if key != ".hljs" || (cssProp.lowercased() != "background-color" && cssProp.lowercased() != "background") {
                    resultString += "\(cssProp):\(val);"
                }
            }

            resultString += "}"
        }

        return resultString
    }

    private func strippedThemeToTheme(_ theme: HRThemeStringDict) -> HRThemeDict {

        var returnTheme = HRThemeDict()
        for (className, props) in theme {
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

    private func fontForCSSStyle(_ fontStyle:String) -> HRFont {

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

    private func colourFromHexString (_ hex:String) -> HRColor {

        var colourString:String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            colourString = (colourString as NSString).substring(from: 1)
        } else {
            switch colourString {
            case "white":
                return HRColor(white: 1, alpha: 1)
            case "black":
                return HRColor(white: 0, alpha: 1)
            case "red":
                return HRColor(red: 1, green: 0, blue: 0, alpha: 1)
            case "green":
                return HRColor(red: 0, green: 1, blue: 0, alpha: 1)
            case "blue":
                return HRColor(red: 0, green: 0, blue: 1, alpha: 1)
            default:
                return HRColor.gray
            }
        }

        if colourString.count != 6 && colourString.count != 3 {
            return HRColor.gray
        }

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0;
        var divisor: CGFloat

        if colourString.count == 6 {
            let rString = (colourString as NSString).substring(to: 2)
            let gString = ((colourString as NSString).substring(from: 2) as NSString).substring(to: 2)
            let bString = ((colourString as NSString).substring(from: 4) as NSString).substring(to: 2)

            Scanner(string: rString).scanHexInt64(&r)
            Scanner(string: gString).scanHexInt64(&g)
            Scanner(string: bString).scanHexInt64(&b)

            divisor = 255.0
        } else {
            let rString = (colourString as NSString).substring(to: 1)
            let gString = ((colourString as NSString).substring(from: 1) as NSString).substring(to: 1)
            let bString = ((colourString as NSString).substring(from: 2) as NSString).substring(to: 1)

            Scanner(string: rString).scanHexInt64(&r)
            Scanner(string: gString).scanHexInt64(&g)
            Scanner(string: bString).scanHexInt64(&b)

            divisor = 15.0
        }

        return HRColor(red: CGFloat(r) / divisor, green: CGFloat(g) / divisor, blue: CGFloat(b) / divisor, alpha: CGFloat(1))
    }
}
