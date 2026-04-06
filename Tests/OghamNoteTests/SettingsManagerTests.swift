import XCTest
@testable import OghamNote

@MainActor
final class SettingsManagerTests: XCTestCase {
    
    var settings: SettingsManager!
    
    override func setUp() async throws {
        try await super.setUp()
        settings = await SettingsManager()
    }
    
    override func tearDown() {
        settings = nil
        super.tearDown()
    }
    
    func testInitialSettings() {
        // Defaults
        XCTAssertTrue(settings.isSyntaxHighlightingEnabled)
        XCTAssertTrue(settings.isRelativeLineNumbersEnabled)
    }
    
    func testPersistence() {
        settings.isSyntaxHighlightingEnabled = false
        XCTAssertFalse(settings.isSyntaxHighlightingEnabled)
        
        // Reset and check if it stayed false (AppStorage uses same UserDefaults)
        let newSettings = SettingsManager()
        XCTAssertFalse(newSettings.isSyntaxHighlightingEnabled)
        
        // Cleanup
        settings.isSyntaxHighlightingEnabled = true
    }
}
