import XCTest
@testable import Highlighter

final class HighlighterTests: XCTestCase {
    
    var hr: Highlighter? = nil
    
    
    override func setUp() {
        
        self.hr = Highlighter.init()
        XCTAssert(hr != nil)
    }
    
    
    func testBadLanguage() {
        
        // Test trapping of a bad language name
        
        let result: NSAttributedString? = self.hr!.highlight("", as: "fintlewoodlewix@1")
        XCTAssert(result == nil)
    }
    
    
    func testSetThemeBad() {
        
        // Test trapping of a bad theme name
        
        let result: Bool = self.hr!.setTheme("fintlewoodlewix@1")
        XCTAssert(!result)
    }
    
    
    func testSetThemeDefaultFont() {
        
        let _ = self.hr!.setTheme("agate")
        let font: NSFont = self.hr!.theme.codeFont
        XCTAssert(font.fontName == "Courier" && font.pointSize == 14.0)
    }
    
    
    func testAvailableThemes() {
        
        // Test Highlight.js contains at least one theme
        
        let result: [String] = self.hr!.availableThemes()
        XCTAssert(result.count > 0)
    }
    
    
    func testSupportedLanguages() {
        
        // Test Highlight.js supports at least one language

        let result: [String] = self.hr!.supportedLanguages()
        XCTAssert(result.count > 0)
    }
    
    
    func testColourFromHexStringGood() {
        
        // Test colour decoding -- all should be processed as valid colours
        
        // Six-digit RGB
        var result: NSColor = self.hr!.theme.colourFromHexString("#808000")
        XCTAssert(result.redComponent > 0.49 &&
                    result.redComponent < 0.56 &&
                    result.greenComponent > 0.49 &&
                    result.greenComponent < 0.56 &&
                    result.blueComponent == 0.0
        )
        
        // Three-digit RGB
        result = self.hr!.theme.colourFromHexString("#444")
        XCTAssert(result.redComponent > 0.2 &&
                    result.redComponent < 0.29 &&
                    result.blueComponent > 0.2 &&
                    result.greenComponent < 0.29 &&
                    result.blueComponent > 0.2 &&
                    result.blueComponent < 0.29
        )
        
        // Eight-digit RGB + Alpha
        result = self.hr!.theme.colourFromHexString("#80800080")
        XCTAssert(result.alphaComponent > 0.49 &&
                    result.alphaComponent < 0.56
        )
        
        // CSS entity
        result = self.hr!.theme.colourFromHexString("red")
        XCTAssert(result.redComponent == 1.0 &&
                    result.blueComponent == 0.0 &&
                    result.greenComponent == 0.0
        )
    }
    
    
    func testColourFromHexStringBad() {
        
        // Test colour decoding -- all should be trapped as bad colours
        
        // Unknown CSS entity
        var result = self.hr!.theme.colourFromHexString("olive")
        XCTAssert(result == NSColor.gray)
        
        // Bad hex value 1
        result = self.hr!.theme.colourFromHexString("#ZZZ")
        XCTAssert(result.redComponent == 0.0 &&
                    result.blueComponent == 0.0 &&
                    result.greenComponent == 0.0
        )
        
        // Bad hex value 2
        result = self.hr!.theme.colourFromHexString("#aaaaa")
        XCTAssert(result == NSColor.gray)
    }
    
    
}
