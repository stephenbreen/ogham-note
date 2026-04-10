import XCTest
@testable import OghamNote

@MainActor
final class CompoundCommandTests: XCTestCase {
    
    var engine: VimEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        engine = await VimEngine()
    }
    
    func testDeleteWord() {
        let text = "Hello world swift"
        engine.setBuffer(text)
        
        // Move to start of "world"
        engine.handleInput("w", currentText: text, currentSelection: NSRange(location: 0, length: 0))
        
        // dw
        engine.handleInput("d", currentText: text, currentSelection: NSRange(location: 6, length: 0))
        engine.handleInput("w", currentText: text, currentSelection: NSRange(location: 6, length: 0))
        
        engine.onTextChange = { newText in
            XCTAssertEqual(newText, "Hello swift")
        }
    }
    
    func testDeleteInnerWord() {
        let text = "Hello world swift"
        engine.setBuffer(text)
        
        // diw inside "world"
        engine.handleInput("d", currentText: text, currentSelection: NSRange(location: 8, length: 0))
        engine.handleInput("i", currentText: text, currentSelection: NSRange(location: 8, length: 0))
        engine.handleInput("w", currentText: text, currentSelection: NSRange(location: 8, length: 0))
        
        engine.onTextChange = { newText in
            XCTAssertEqual(newText, "Hello  swift")
        }
    }
    
    func testDeleteLine() {
        let text = "Line 1\nLine 2\nLine 3"
        engine.setBuffer(text)
        
        // dd on Line 2
        engine.handleInput("j", currentText: text, currentSelection: NSRange(location: 0, length: 0))
        engine.handleInput("d", currentText: text, currentSelection: NSRange(location: 7, length: 0))
        engine.handleInput("d", currentText: text, currentSelection: NSRange(location: 7, length: 0))
        
        engine.onTextChange = { newText in
            XCTAssertEqual(newText, "Line 1\nLine 3")
        }
    }
    
    func testDotRepeat() {
        let text = "word1 word2 word3"
        engine.setBuffer(text)
        
        // dw on word1
        engine.handleInput("d", currentText: text, currentSelection: NSRange(location: 0, length: 0))
        engine.handleInput("w", currentText: text, currentSelection: NSRange(location: 0, length: 0))
        
        // Buffer should be "word2 word3"
        // Now '.' on word2
        engine.handleInput(".", currentText: "word2 word3", currentSelection: NSRange(location: 0, length: 0))
        
        engine.onTextChange = { newText in
            XCTAssertEqual(newText, "word3")
        }
    }
}
