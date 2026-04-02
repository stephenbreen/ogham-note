import XCTest
import AppKit
@testable import OghamNote

final class VimKeyMapperTests: XCTestCase {
    
    func testSpecialKeys() {
        // Mocking NSEvent is difficult, but we can test the mapping logic 
        // if we expose the internal mapSpecialKey for testing or simulate events.
        // For now, we'll test the known keycodes.
        
        let escKeyCode: UInt16 = 53
        let bsKeyCode: UInt16 = 51
        let crKeyCode: UInt16 = 36
        
        XCTAssertEqual(VimKeyMapper.string(fromKeyCode: escKeyCode), "<Esc>")
        XCTAssertEqual(VimKeyMapper.string(fromKeyCode: bsKeyCode), "<BS>")
        XCTAssertEqual(VimKeyMapper.string(fromKeyCode: crKeyCode), "<CR>")
    }
}

// Extension to expose internal logic for testing
extension VimKeyMapper {
    static func string(fromKeyCode keyCode: UInt16) -> String? {
        // This is a helper for testing purposes to avoid complex NSEvent mocking
        return mapSpecialKey(keyCode)
    }
}
