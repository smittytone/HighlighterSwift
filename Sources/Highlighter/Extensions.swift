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


extension NSMutableAttributedString {

    /**
     Swap the paragraph style in all of the attributes of
     an NSMutableAttributedString.

     - Parameters:
        - paraStyle: The injected NSParagraphStyle.
    */
    func addParaStyle(with paraStyle: NSParagraphStyle) {

        beginEditing()
        self.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, self.length)) { (value, range, stop) in
            if let _ = value as? NSParagraphStyle {
                removeAttribute(.paragraphStyle, range: range)
                addAttribute(.paragraphStyle, value: paraStyle, range: range)
            }
        }
        endEditing()
    }
}


extension NSAttributedString {

    /**
     Split the instance as per splitting a regular string.

     - Parameters:
        - separatedBy: The string used to split the primary string.

     - Returns: An array of attributed strings, one per split.
     */
    func components(separatedBy separator: String) -> [NSAttributedString] {

        var parts: [NSAttributedString] = []
        let subStrings = self.string.components(separatedBy: separator)
        var range = NSRange(location: 0, length: 0)
        for string in subStrings {
            range.length = string.utf16.count
            let attributedString = attributedSubstring(from: range)
            parts.append(attributedString)
            range.location += range.length + separator.utf16.count
        }
        return parts
    }
}


extension Scanner {

    /**
     Look ahead and return the next character in the sequence without
     altering the current location of the scanner.

     - Parameters:
        - in: The string being scanned.

     - Returns The next character as a string.
     */
    func getNextCharacter(in outer: String) -> String {

        let string: NSString = self.string as NSString
        let idx: Int = self.currentIndex.utf16Offset(in: outer)
        let nextChar: String = string.substring(with: NSMakeRange(idx, 1))
        return nextChar
    }


    /**
     Step over the next character.
     */
    func skipNextCharacter() {

        self.currentIndex = self.string.index(after: self.currentIndex)
    }
}


#if os(OSX)
extension NSColor {

    /**
     Generate a new NSColor from an RGB+A hex string..

     - Parameters:
        - hex: The RGB+A hex string, eg.`AABBCCFF`.

     - Returns: An NSColor object.
     */
    static func hexToColour(_ hex: String) -> NSColor {

        var colourString: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            let index = colourString.index(colourString.startIndex, offsetBy: 1)
            colourString = String(colourString[index...])
        }

        // Colours in hex strings have 6 (`AABBCC`) or 8 (6 + alpha, `AABBCCDD`) values
        if colourString.count != 8 && colourString.count != 6 {
            return .red
        }

        func hexToFloat(_ hs: String) -> CGFloat {
            // No alpha value supplied, so assume full opacity is required
            return CGFloat(UInt8(hs, radix: 16) ?? 255)
        }

        let cns: NSString = colourString as NSString
        let red: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 0, length: 2))) / 255.0
        let green: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 2, length: 2))) / 255.0
        let blue: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 4, length: 2))) / 255.0
        let alpha: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 6, length: 2))) / 255.0
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#elseif os(iOS)
extension UIColor {

    /**
     Return the colour's alpha value.
     */
    var alphaComponent: CGFloat {

        var red: CGFloat   = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat  = 0.0
        var alpha: CGFloat = 0.0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return alpha
    }


    static var labelColor: UIColor {

        return .label
    }


    /**
     Generate a new NSColor from an RGB+A hex string..

     - Parameters:
        - hex: The RGB+A hex string, eg.`AABBCCFF`.

     - Returns: An NSColor object.
     */
    static func hexToColour(_ hex: String) -> UIColor {

        var colourString: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            let index = colourString.index(colourString.startIndex, offsetBy: 1)
            colourString = String(colourString[index...])
        }

        // Colours in hex strings have 6 (`AABBCC`) or 8 (6 + alpha, `AABBCCDD`) values
        if colourString.count != 8 && colourString.count != 6 {
            return .red
        }

        func hexToFloat(_ hs: String) -> CGFloat {
            // No alpha value supplied, so assume full opacity is required
            return CGFloat(UInt8(hs, radix: 16) ?? 255)
        }

        let cns: NSString = colourString as NSString
        let red: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 0, length: 2))) / 255.0
        let green: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 2, length: 2))) / 255.0
        let blue: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 4, length: 2))) / 255.0
        let alpha: CGFloat = hexToFloat(cns.substring(with: NSRange(location: 6, length: 2))) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif
