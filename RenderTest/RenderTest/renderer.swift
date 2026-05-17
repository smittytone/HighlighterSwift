//
//  rendertest.swift
//  RenderTest
//
//  Created by Tony Smith on 17/05/2026.
//

import AppKit
import Clicore
import Highlighter


class Rendertest {

    private var highlighter: Highlighter? = nil
    private var themes: [String] = []


    public func renderThemes() {

        let renderFrame: CGRect = NSMakeRect(0, 0, 512, 268)
        let fm: FileManager = FileManager()
        let homeFolder: String = fm.homeDirectoryForCurrentUser.path

        // Load in the code sample we'll preview the themes with
        let codeSample = """
        import Foundation\n\n@objc class Person: Entity {
            var name: String!
            var age:  Int!

            init(name: String, age: Int) {
                /* /* ... */ */
            }

            // Return a descriptive string for this person
            func description(offset: Int = 0) -> String {
                return "\\(name) is \\(age + offset) years old"
            }
        }
        """

        self.highlighter = Highlighter()
        guard let hltr = self.highlighter else { return }
        self.themes = hltr.availableThemes()

        for theme in self.themes {
            hltr.setTheme(theme)

            let ptv = NSTextView(frame: renderFrame)
            ptv.isSelectable = false

            if let renderTextStorage: NSTextStorage = ptv.textStorage {
                renderTextStorage.beginEditing()
                if let pas = hltr.highlight(codeSample, as: "swift") {
                    renderTextStorage.setAttributedString(pas)
                }

                renderTextStorage.endEditing()
                ptv.backgroundColor = hltr.theme.themeBackgroundColour
            }

            if let imageRep: NSBitmapImageRep = ptv.bitmapImageRepForCachingDisplay(in: renderFrame) {
                ptv.cacheDisplay(in: renderFrame, to: imageRep)
                if let data: Data = imageRep.representation(using: .png, properties: [:]) {
                    do {
                        let path: String = homeFolder + "/" + theme + "@2x.png"
                        try data.write(to: URL(fileURLWithPath: path))
                    } catch {
                        // NOP
                    }
                }
            }
        }
    }



}
