import XCTest
import AppKit
@testable import OghamNote

final class TextEntryZoomTests: XCTestCase {
    @MainActor
    func testHeaderFontFeedbackLoop() {
        let textView = EditorTextView(frame: .zero)
        let baseFontSize: CGFloat = 14
        textView.font = .monospacedSystemFont(ofSize: baseFontSize, weight: .regular)
        
        let theme = AppTheme.nord
        
        textView.string = "# Header"
        
        // Initial highlight
        textView.highlightSyntax(with: theme)
        
        let initialFont = textView.font
        XCTAssertNotNil(initialFont)
        print("Initial font size: \(initialFont?.pointSize ?? 0)")
        
        // Simulate multiple typing events that trigger highlight
        let stableSize = textView.font?.pointSize ?? 0
        XCTAssertGreaterThanOrEqual(stableSize, baseFontSize)
        
        for i in 1...5 {
            textView.string = "# Header \(i)"
            textView.highlightSyntax(with: theme)
            XCTAssertEqual(textView.font?.pointSize, stableSize, "Font size should remain stable across iterations")
            print("Font size after iteration \(i): \(textView.font?.pointSize ?? 0)")
        }
    }
}
