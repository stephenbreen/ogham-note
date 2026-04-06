import XCTest
@testable import OghamNote

@MainActor
final class SearchManagerTests: XCTestCase {
    
    var searchManager: SearchManager!
    
    override func setUp() async throws {
        try await super.setUp()
        searchManager = await SearchManager()
    }
    
    override func tearDown() {
        searchManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertTrue(searchManager.results.isEmpty)
        XCTAssertFalse(searchManager.isSearching)
        XCTAssertEqual(searchManager.searchText, "")
    }
    
    func testSearchWithEmptyQuery() {
        searchManager.searchText = ""
        searchManager.performSearch(in: URL(fileURLWithPath: "/tmp"))
        XCTAssertTrue(searchManager.results.isEmpty)
    }
}
