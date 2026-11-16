/*
 *  HighlighterSwift
 *  Extensions.swift
 *  Copyright 2026, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */

#if os(macOS)
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
    func getNextCharacter(in outer: String = "") -> String {

        return getNextChar()
    }


    /**
     Look ahead and return the next character in the sequence without
     altering the current location of the scanner.

     FROM 4.0.0

     - Returns The next character as a string, or an empty one.
     */
    func getNextChar() -> String {

        if self.currentIndex < self.string.endIndex {
            let nextIndex = self.string.index(after: self.currentIndex)
            return String(self.string[self.currentIndex..<nextIndex])
        }

        return ""
    }


    /**
     Step over the next character.
     */
    func skipNextCharacter() {

        // FROM 4.0.0
        // Add check to hopefully fix certain Thumbnailer crashes
        if self.currentIndex < self.string.endIndex {
            self.currentIndex = self.string.index(after: self.currentIndex)
        }
    }
}


#if os(macOS)
extension NSColor {

    /**
     Generate a new NSColor from an RGB+A hex string..

     - Parameters:
        - hex: The RGB+A hex string, eg.`AABBCCFF`.

     - Returns: An NSColor object.
     */
    static func hexToColour(_ hex: String) -> NSColor {

        var colourString = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            // The colour is defined by a hex value
            colourString = String(colourString.dropFirst(1))
        }

        // Colours in hex strings have 3, 6 or 8 (6 + alpha) values
        guard [8, 6, 3].contains(colourString.count) else { return NSColor.gray }
        guard let colourValue = Int(colourString, radix: 16) else { return NSColor.gray }

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
        var divisor: CGFloat = 255.0
        var a: CGFloat = 1.0

        if colourString.count == 6 {
            r = UInt64((colourValue >> 16) & 0xFF)
            g = UInt64((colourValue >> 8) & 0xFF)
            b = UInt64(colourValue & 0xFF)
        } else if colourString.count == 8 {
            r = UInt64((colourValue >> 24) & 0xFF)
            g = UInt64((colourValue >> 16) & 0xFF)
            b = UInt64((colourValue >> 8) & 0xFF)
            a = CGFloat(colourValue & 0xFF) / divisor
        } else {
            // Decode a three-character hex string
            r = UInt64((colourValue >> 8) & 0xF)
            g = UInt64((colourValue >> 4) & 0xF)
            b = UInt64(colourValue & 0xF)
            divisor = 15.0
        }

        return NSColor(red: CGFloat(r) / divisor, green: CGFloat(g) / divisor, blue: CGFloat(b) / divisor, alpha: a)
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

        var colourString = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            // The colour is defined by a hex value
            colourString = String(colourString.dropFirst(1))
        }

        // Colours in hex strings have 3, 6 or 8 (6 + alpha) values
        guard [8, 6, 3].contains(colourString.count) else { return UIColor.gray }
        guard let colourValue = Int(colourString, radix: 16) else { return UIColor.gray }

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
        var divisor: CGFloat = 255.0
        var a: CGFloat = 1.0

        if colourString.count == 6 {
            r = UInt64((colourValue >> 16) & 0xFF)
            g = UInt64((colourValue >> 8) & 0xFF)
            b = UInt64(colourValue & 0xFF)
        } else if colourString.count == 8 {
            r = UInt64((colourValue >> 24) & 0xFF)
            g = UInt64((colourValue >> 16) & 0xFF)
            b = UInt64((colourValue >> 8) & 0xFF)
            a = CGFloat(colourValue & 0xFF) / divisor
        } else {
            // Decode a three-character hex string
            r = UInt64((colourValue >> 8) & 0xF)
            g = UInt64((colourValue >> 4) & 0xF)
            b = UInt64(colourValue & 0xF)
            divisor = 15.0
        }

        return UIColor(red: CGFloat(r) / divisor, green: CGFloat(g) / divisor, blue: CGFloat(b) / divisor, alpha: a)
    }
}
#endif
