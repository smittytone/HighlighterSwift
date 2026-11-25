/*
 *  HighlighterSwift
 *  Shims.swift
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

/**
 Basic imports and typealiases.
 */
#if os(macOS)
import AppKit
public typealias HSColor = NSColor
public typealias HSFont  = NSFont
#else
import UIKit
public typealias HSColor = UIColor
public typealias HSFont  = UIFont
#endif


/**
 Set type aliases according to which Swift is being run and,
 in the second case, if we're running on iOS
 */
public typealias AttributedStringKey = NSAttributedString.Key

#if os(macOS)
public typealias TextStorageEditActions = NSTextStorageEditActions
#else
public typealias TextStorageEditActions = NSTextStorage.EditActions
#endif
