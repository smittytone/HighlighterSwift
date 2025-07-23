/*
 *  Highlighter.swift
 *  Copyright 2025, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */


import Foundation

/**
 Basic imports and typealiases.
 */
#if os(OSX)
    import AppKit
    public typealias HRColor = NSColor
    public typealias HRFont  = NSFont
#elseif os(iOS)
    import UIKit
    public typealias HRColor = UIColor
    public typealias HRFont  = UIFont
#endif


/**
 Set type aliases according to which Swift is being run and,
 in the second case, if we're running on iOS

 NOTE This is probably unnecessary now since the Swift Package
      mandates Swift 5.3
 */
#if swift(>=4.2)
    public typealias AttributedStringKey = NSAttributedString.Key
#else
    public typealias AttributedStringKey = NSAttributedStringKey
#endif

#if swift(>=4.2) && os(iOS)
    public typealias TextStorageEditActions = NSTextStorage.EditActions
#else
    public typealias TextStorageEditActions = NSTextStorageEditActions
#endif
