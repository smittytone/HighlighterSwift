/*
 *  HighlighterSwift
 *  LoggingOptions.swift
 *  Copyright 2026, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  MIT License
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:

 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import os


/**
 Holder for current and future logging choices.
 */
public struct LoggingOptions {

    public var highlighter: HighlighterLoggingOptions = HighlighterLoggingOptions()
    public var theme: ThemeLoggingOptions = ThemeLoggingOptions()
    public let logger = Logger()
}


public struct HighlighterLoggingOptions {

#if DEBUG
    public var showInitErrors: Bool = true
    public var showCSSErrors: Bool = true
#else
    public var showInitErrors: Bool = false
    public var showCSSErrors: Bool = false
#endif
}


public struct ThemeLoggingOptions {

#if DEBUG
    public var showMissingStyles: Bool = true
    public var showBadColour: Bool = true
#else
    public var showMissingStyles: Bool = false
    public var showBadColour: Bool = false
#endif
}

