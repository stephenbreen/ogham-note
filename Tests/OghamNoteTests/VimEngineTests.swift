import XCTest
@testable import OghamNote

@MainActor
final class VimEngineTests: XCTestCase {
    
    var engine: VimEngine!
    
    override func setUp() {
        super.setUp()
        engine = VimEngine()
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    func testInitialMode() {
        XCTAssertEqual(engine.mode, .normal)
    }
    
    func testModeSwitching() {
        engine.handleInput("i", currentText: "", currentSelection: NSRange(location: 0, length: 0))
        XCTAssertEqual(engine.mode, .insert)
        
        engine.handleInput("<Esc>", currentText: "", currentSelection: NSRange(location: 0, length: 0))
        XCTAssertEqual(engine.mode, .normal)
        
        engine.handleInput(":", currentText: "", currentSelection: NSRange(location: 0, length: 0))
        XCTAssertEqual(engine.mode, .command)
    }
    
    func testHorizontalMotions() {
        let text = "Hello"
        var selection = NSRange(location: 2, length: 0)
        
        engine.onSelectionChange = { newRange in
            selection = newRange
        }
        
        // Move left (h)
        engine.handleInput("h", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 1)
        
        // Move right (l)
        engine.handleInput("l", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 2)
    }
    
    func testWordMotions() {
        let text = "Hello world swift"
        var selection = NSRange(location: 0, length: 0)
        
        engine.onSelectionChange = { newRange in
            selection = newRange
        }
        
        // Move word forward (w)
        engine.handleInput("w", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 6) // Start of "world"
        
        engine.handleInput("w", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 12) // Start of "swift"
        
        // Move word backward (b)
        engine.handleInput("b", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 6) // Start of "world"
    }
    
    func testVerticalMotions() {
        let text = "Line 1\nLine 2\nLine 3"
        var selection = NSRange(location: 0, length: 0)
        
        engine.onSelectionChange = { newRange in
            selection = newRange
        }
        
        // Move down (j)
        engine.handleInput("j", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 7) // Start of Line 2
        
        // Move down again (j)
        engine.handleInput("j", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 14) // Start of Line 3
        
        // Move up (k)
        engine.handleInput("k", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 7) // Start of Line 2
    }
    
    func testLineStartEnd() {
        let text = "Hello World"
        var selection = NSRange(location: 5, length: 0)
        
        engine.onSelectionChange = { newRange in
            selection = newRange
        }
        
        // Move to start (0)
        engine.handleInput("0", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 0)
        
        // Move to end ($)
        engine.handleInput("$", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 11)
    }
    
    func testDeletion() {
        let text = "Hello"
        var currentText = text
        var selection = NSRange(location: 1, length: 0) // On 'e'
        
        engine.onTextChange = { newText in
            currentText = newText
        }
        
        engine.handleInput("x", currentText: currentText, currentSelection: selection)
        XCTAssertEqual(currentText, "Hllo")
    }
    
    func testBoundaryMotions() {
        let text = "Hi"
        var selection = NSRange(location: 0, length: 0)
        
        engine.onSelectionChange = { newRange in
            selection = newRange
        }
        
        // Move left at start
        engine.handleInput("h", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 0)
        
        // Move right past end
        selection = NSRange(location: 2, length: 0)
        engine.handleInput("l", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.location, 2)
    }
    
    func testVisualLineMode() {
        let text = "Line 1\nLine 2\nLine 3"
        var selection = NSRange(location: 0, length: 0)
        
        engine.onSelectionChange = { newRange in
            selection = newRange
        }
        
        // Enter Visual Line mode (V)
        engine.handleInput("V", currentText: text, currentSelection: selection)
        XCTAssertEqual(engine.mode, .visualLine)
        XCTAssertEqual(selection.length, 7) // Entire first line including \n
        
        // Move down (j)
        engine.handleInput("j", currentText: text, currentSelection: selection)
        XCTAssertEqual(selection.length, 14) // Lines 1 and 2
    }
}
