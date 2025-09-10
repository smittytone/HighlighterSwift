# HighlighterSwift 1.2.0

This library provides a Swift wrapper for the popular [Highlight.js](https://highlightjs.org/) code highlighting utility.

![Far theme example](Images/atom-one-dark.png)

It is a more up-to-date version of Juan Pablo Illanes’ [Highlightr](https://github.com/raspu/Highlightr) and relies heavily upon code from that project, which is unfortunately no longer fully maintained.

### Improvements and Changes

*Highlightr* makes use of *Highlight.js 9.13.4*, but the most recent release of the JavaScript library is 11.11.1. This is the version used by **HighlighterSwift**. Earlier versions of *Highlight.js* are not considered secure.

**HighlighterSwift** adds support for alpha values in CSS colours, eg. `#808080AA`, not present in Highlightr.

Unlike *Highlightr*, **HighlighterSwift** parses *Highlight.js* themes for separate declarations of the same style. For example, *Hybrid* contains the following CSS:

```css
.hljs{display:block;overflow-x:auto;padding:.5em;background:#1d1f21}.hljs span::selection,.hljs::selection{background:#373b41}.hljs{color:#c5c8c6}
```

The `hljs.color` attribute is added to `hljs.display`, `hljs.overflow-x`, `hljs.padding` and `hljs.background`, it doesn’t replace them.

**HighlighterSwift** was designed from the ground up as a Swift Package. Support for legacy package managers is not included. *Highlightr* supports CocoaPods and Carthage.

**HighlighterSwift** is more deeply commented and the code is presented in a more consistent style.

A number of functions have been given extra parameters, primarily to add font selection when setting themes and initiating *Theme* objects. Redundant code has been removed. Some parameters have been renamed.

Unit tests have been added, and more will come, I hope.

![Far theme example](Images/far.png)

#### Why not update Highlightr?

**HighlighterSwift** was created to meet the needs of a specific project, which was originally conceived with a modified version *Hightlightr* in mind. Some of the changes listed above are breaking, and so I feel it’s not appropriate to just inflict them on the *Hightlightr* source, especially when there are many outstanding pull requests yet to be addressed. But I’m not opposed to pulling in my changes if the community requests that.

**HighlighterSwift** is released under the same [licence](#licence) as *Highlightr*, allowing developers to select either, both or a mix of the two.

## Platform Support

**HighlighterSwift** supports macOS 11 (Big Sur) and up, iOS (iPadOS) 12 and up, tvOS 12 and up, and visionOS 1 and up. iOS, tvOS and visionOS support remains untested, however.

## Installation

To add **HighlighterSwift** to your project, use Xcode to add it as a Swift Package at this repo’s URL. The library contains the *Highlight.js* code and themes.

**Note** This project was begun to support another, so some themes have been modified slightly to meet the needs of that other project. For example, background images have been removed from the Brown Paper, Greyscale, Schoolbook and Pojoacque themes (*Highlight.js* is also starting to do this); the two Kimbies have been renamed for consistency; colours have been formalised as hex values.

## Usage

Instantiate a *Highlighter* object. Its `init()` function returns an optional, which will be `nil` if the `Highlight.min.js` file could not be found or is non-functional, or the `Default` theme CSS file is missing:

```swift
if let highlighter: Highlighter = Highlighter() {
    ...
}
```

You can set a specific theme using the `setTheme()` function:

```swift
highlighter.setTheme("atom-one-light")
```

You can apply your chosen font at this time too rather than fall back on the default, 14pt Courier:

```swift
highlighter.setTheme("atom-one-light", withFont: "Menlo-Regular", ofSize: 16.0)
```

Having set the theme, you can specify a line spacing value:

```swift
highlighter.theme.lineSpacing = self.lineSpacing * self.fontSize
```

and/or a paragraph spacing value:

```swift
highlighter.theme.paraSpacing = 1.0
```

A value of `0.0` for `lineSpacing` is equivalent to single spacing. `paraSpacing` is the space in points added at the end of the paragraph — use `0.0` for no additional spacing (the default).

Both values must be non-negative. Negative values be replaced with the default values.

**Note** As shown above, these new values are applied to the `Highlighter` instance’s `theme` property.

You can set or change your preferred font later by using `setCodeFont()`, which takes an *NSFont* or *UIFont* instance configured for the font and text size you want, and is called on the *Highlighter* instance’s `theme` property:

```swift
let font: NSFont = NSFont.init(name: "Menlo-Regular", size: 12.0)!
highlighter.theme.setCodeFont(font)
```

Finally, get an optional *NSAttributedString* containing the formatted code:

```swift
if let displayString: NSAttributedString = highlighter.highlight(codeString, as: "swift") {
    myTextView.textStorage!.addAttributedString(displayString)
}
```

![Far theme example](Images/github-gist.png)

The second parameter is the name of language you’re rendering. If you leave out this parameter, or pass `nil`, *Highlighter* will use *Highlight.js*’ language detection feature.

From 1.2.0, pass in a fourth parameter, an instance of a `LineNumberingData` structure, to instruct **HighlighterSwift** to add line numbers to the code. The default for this parameter is `nil` (don’t add line numbers).

```swift
public struct LineNumberData {

    public var numberStart: Int = 1
    public var minWidth: Int = 2
    public var separator: String = "  "
    public var usingDarkTheme: Bool = false
    public var lineBreak: String = "\n"
    public var fontSize: CGFloat = 16.0
}
```

`LineNumberingData` properties allow you to specify:

* The initial line number of the rendered code. Default: 1.
* The minimum number of digits in the line number. Default: 2. This will always be overriden by the maximum line number. For example, if you set this to 3 (so the first line might be rendered as `001`) but there are a thousand or more lines in the code, the first line will be rendered as `0001`.
* A separator string to be placed between the line number and the line itself. Default: two spaces.
* Is the theme you are using dark? Default: `false`.
* The line-break string used in the tokenized source code. Default: `\n`. **Note** You should not need to change this.
* The size of the line number font. Typically this will match your code font’s size. Default: 16.0 points.

All these values are optional.

```swift
var lineNumberingData = LineNumberData()
lineNumberingData.minWidth = 4
lineNumberingData.numberStart = 100
lineNumberingData.usingDarkTheme = !isMacInLightMode()
lineNumberingData.fontSize = self.settings.fontSize

if let displayString: NSAttributedString = highlighter.highlight(codeString, as: "swift", lineNumbering: lineNumberingData) {
    myTextView.textStorage!.addAttributedString(displayString)
}
```

You can get a list of supported languages by the name they are known to *Highlight.js* by calling `supportedLanguages()` — it returns an array of strings.

The function `availableThemes()` returns a list of the installed themes.

## Release Notes

Please see [CHANGELOG.md](CHANGELOG.md).

## Licences

**HighlighterSwift**, like *Highlightr* before it, is released under the terms of the MIT Licence. *Hightlight.js* is released under the BSD 3-Clause Licence.

**HighlighterSwift** is &copy; 2025, Tony Smith. Portions are &copy; 2016, Juan Pablo Illanes. Other portions are &copy; 2006-2025, Josh Goebel and other contributors.
