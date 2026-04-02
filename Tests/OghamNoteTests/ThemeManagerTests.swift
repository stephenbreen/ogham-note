import XCTest
@testable import OghamNote

@MainActor
final class ThemeManagerTests: XCTestCase {
    
    var themeManager: ThemeManager!
    
    override func setUp() {
        super.setUp()
        themeManager = ThemeManager()
    }
    
    override func tearDown() {
        themeManager = nil
        super.tearDown()
    }
    
    func testInitialTheme() {
        XCTAssertEqual(themeManager.currentTheme.id, "nord")
    }
    
    func testSetTheme() {
        themeManager.setTheme(.dracula)
        XCTAssertEqual(themeManager.currentTheme.id, "dracula")
    }
}
