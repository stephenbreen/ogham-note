import XCTest
@testable import OghamNote

@MainActor
final class ThemeManagerTests: XCTestCase {
    
    var themeManager: ThemeManager!
    
    override func setUp() async throws {
        try await super.setUp()
        themeManager = await ThemeManager()
        themeManager.setTheme(.nord)
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
