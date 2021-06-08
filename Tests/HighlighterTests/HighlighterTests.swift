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
        
        let result: NSAttributedString? = self.hr!.highlight("", as: "bollocks")
        XCTAssert(result == nil)
    }
    
    
    func testBadTheme() {
        
        // Test trapping of a bad theme name
        
        let result: Bool = self.hr!.setTheme("bollocks")
        XCTAssert(!result)
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
    
    
    func testColourFromHexString() {
        
        // Test private functions
        
        //let result: NSColor = self.hr!.theme.publicColourFromHexString("#808000")
        //XCTAssert(result.redComponent == 0.5 && result.greenComponent == 0.5)
    }
}
