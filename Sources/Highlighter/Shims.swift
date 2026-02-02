/*
 *  Highlighter.swift
 *  Copyright 2026, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */

/**
 Basic imports and typealiases.
 */
#if os(macOS)
import AppKit
public typealias HRColor = NSColor
public typealias HRFont  = NSFont
#else
import UIKit
public typealias HRColor = UIColor
public typealias HRFont  = UIFont
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
