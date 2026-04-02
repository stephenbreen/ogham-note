import XCTest
@testable import OghamNote

@MainActor
final class SearchManagerTests: XCTestCase {
    
    var searchManager: SearchManager!
    
    override func setUp() {
        super.setUp()
        searchManager = SearchManager()
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
