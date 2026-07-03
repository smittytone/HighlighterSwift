/*
 *  Highlighter.swift
 *  Copyright 2026, Tony Smith
 *  Copyright 2016, Juan-Pablo Illanes
 *
 *  Licence: MIT
 */


/**
 Holder for current and future logging choices.
 */
public struct LoggingOptions {

    public var highlighter: HighlighterLoggingOptions = HighlighterLoggingOptions()
    public var theme: ThemeLoggingOptions = ThemeLoggingOptions()
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


public struct HighlighterLoggingOptions {

#if DEBUG
    public var showInitErrors: Bool = true
    public var showCSSErrors: Bool = true
#else
    public var showInitErrors: Bool = true
    public var showCSSErrors: Bool = false
#endif
}
