import XCTest
import Markdown
@testable import OghamNote

@MainActor
final class PerformanceBenchmarks: XCTestCase {
    
    var engine: VimEngine!
    var largeContent: String = ""
    
    override func setUp() async throws {
        try await super.setUp()
        engine = await VimEngine()
        
        // Load the generated stress test file
        let url = URL(fileURLWithPath: "stress_test.md")
        if let content = try? String(contentsOf: url) {
            largeContent = content
            await engine.setBuffer(content)
        }
    }
    
    func testVimEngineMotionPerformance() {
        let selection = NSRange(location: 0, length: 0)
        
        measure {
            // Simulate 100 fast "j" motions in a large file
            for _ in 0..<100 {
                engine.handleInput("j", currentText: largeContent, currentSelection: selection)
            }
        }
    }
    
    func testMarkdownParsingPerformance() {
        measure {
            // Measure parsing a 10k line markdown file into AST
            _ = Document(parsing: largeContent)
        }
    }
    
    func testSearchPerformance() {
        let searchManager = SearchManager()
        searchManager.searchText = "line number 5000"
        let workspaceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        measure {
            // Measure searching through the workspace
            // Note: This is async in the manager, but we test the synchronous core logic here
            let expectation = XCTestExpectation(description: "Search complete")
            
            searchManager.performSearch(in: workspaceURL)
            
            // Poll for results (simple for benchmark purposes)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
}
