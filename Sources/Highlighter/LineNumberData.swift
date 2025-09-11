/*
 *  Highlighter.swift
 *  Copyright 2025, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */

import Foundation


/**
 A structure used to specify a line-numbering operation.`
 */
public struct LineNumberData {

    // MARK: Public Computed Properties

    public var numberStart: Int {                           // The first line number.
        get {                                               // Negative values reset any existint value to zero.
            return self.baseStart
        }

        set (newValue) {
            if newValue > 1 {
                self.baseStart = newValue
            } else {
                self.baseStart = 1
            }
        }
    }

    public var minWidth: Int {                              // The minimum number of line-number digits to show,
        get {                                               // eg. 3 for `001`, 4 for `0001` etc.
            return self.baseMinWidth                        // This will always be overriden if highest line number
        }                                                   // has more digits than this value.
                                                            // The default, and smallest acceptable value is 2.
        set (newValue) {
            if newValue > 2 {
                self.baseMinWidth = newValue
            } else {
                self.baseMinWidth = 2
            }
        }
    }

    public var separator: String {                          // A string placed between the line number and the line.
        get {                                               // Empty strings are converted to two spaces (the default value)
            return self.baseSeparator
        }

        set (newValue) {
            if newValue == "" {
                self.baseSeparator = "  "
            } else {
                self.baseSeparator = newValue
            }
        }
    }


    // MARK: Public Properties

    public var usingDarkTheme: Bool = false                 // Is the host theme dark? Default: `false`.
    public var lineBreak: String = "\n"                     // The line-break character emitted by the rendering code.
                                                            // It should not be necessary to change this.
    public var fontSize: CGFloat = 16.0                     // The base font size.


    // MARK: Private Properties

    private var baseSeparator: String = "  "
    private var baseStart: Int = 0
    private var baseMinWidth: Int = 2


    // MARK: Constructors

    public init() {
        self.usingDarkTheme = false
        self.lineBreak = "\n"
        self.baseSeparator = "  "
        self.baseStart = 1
        self.baseMinWidth = 1
    }

    public init(usingDarkTheme: Bool = false, lineBreak: String = "\n", fontSize: CGFloat = 16.0) {
        self.usingDarkTheme = usingDarkTheme
        self.lineBreak = lineBreak
        self.fontSize = fontSize
    }
}
