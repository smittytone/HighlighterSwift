# HighlighterSwift 1.0.0

This library provides a Swift wrapper for the popular [Highlight.js](https://highlightjs.org/) code highlighting utility.

It is a more up-to-date version of Juan Pablo Illanes’ [Highlightr](https://github.com/raspu/Highlightr) and relies heavily upon code from that project, which is unfortunately now no longer fully maintained.

### Improvements and Changes

Highlightr makes use of Highlight.js 9, but the most recent release of the JavaScript, as of June 2021, is version 11, and the use of version 9 is no longer supported or recommended. HighlighterSwift works with Highlight.js 10.7.3, which continues to receive updates. I hope to update the library to version 11.x in due course.

HighlighterSwift adds support for alpha values in CSS colours, eg. `#808080AA`, not present in Highlightr.

HighlighterSwift was designed from the ground up as a Swift Package. Support for legacy package managers is not included.

HighlighterSwift is more deeply commented and the code is presented in a more consistent style.

#### Why not update Highlightr?

HighlighterSwift was created to meet the needs of a specific project, which was originally conceived with a modified version Hightlightr in mind. The changes, though minimal and mostly in the form ot tweaks to the bundled Highlight.js theme mean it wasn’t considered appropriate to inflict on the Hightlightr source — or to wait for a pull request to be accepted (the last was in 2018). HighlighterSwift is released under the same [licence](#licence) as Highlightr, allowing devs to select either, both or a mix of the two.

## Platform Support

HighlighterSwift supports macOS 10.14 and up, and iOS 12 and up. iOS support is untested, however.

## Installation

To add HighlighterSwift to your project, use Xcode to add it as a Swift Package at this repo’s URL. The library contains the Highlight.js code and themes.

**Note** This project was begun to support another, so some themes have been modified slightly to meet the needs of that other project. For example, background images have been removed from the Brown Paper, Greyscale, Schoolbook and Pojoacque themes; the two Kimbies have been renamed for consistency; colours have been formalised as hex values.

## Usage

Instantiate a Highlighter object. Its *init()* function returns an optional, which will be `nil` if the `Highlight.min.js` could not be found or is non-functional, or the Default theme is missing.

```swift
if let highlighter: Highlighter = Highlighter.init() {
    ...
}
```

You can set a specific theme using the *setTheme()* function:

```swift
highlighter.setTheme(hr.setTheme("atom-one-light")
```

**Note** Set your preferred font using *setCodeFont()*, which takes an NSFont or UIFont instance configured for the font and text size you want and is called on the Highlighter instance’s *theme* property:

```swift
let font: NSFont = NSFont.init(name: "menlo-regular", size: 12.0)!
highlighter.theme.setCodeFont(font)
```

Finally, get an optional NSAttributedString containing the formatted code:

```swift
let displayString: NSAttributedString? = highlighter.highlight(codeString, as: "swift")
```

The second parameter is the name of language you’re rendering. If you leave out this parameter, or pass `nil`, Highlighter will use Highlight.js’ language detection feature.

You can get a list of supported languages by the name they are known to Highlight.js by calling *supportedLanguages()* — it returns an array of strings. The function *availableThemes()* returns a list of the installed themes.

## Release Notes

* 1.0.0 *Unreleased*
    * Initial public release.

## Licences

HighlighterSwift, like Highlightr before it, is released under the terms of the MIT Licence. Hightlight.js is released under the BSD 3-Clause Licence.

HighlighterSwift is &copy; 2021, Tony Smith. Portions are &copy; 2018, Juan Pablo Illanes. Other portions are &copy; 2021, Ivan Sagalaev.
