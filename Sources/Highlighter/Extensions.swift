/*
 *  Highlighter.swift
 *  Copyright 2025, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */

import AppKit


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
