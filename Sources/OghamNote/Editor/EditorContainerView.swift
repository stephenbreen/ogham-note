import SwiftUI
import AppKit

struct EditorContainerView: NSViewRepresentable {
    @Binding var content: String
    @ObservedObject var vimEngine: VimEngine
    let theme: AppTheme
    @ObservedObject var settings: SettingsManager

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let textView = EditorTextView(frame: .zero)
        textView.vimEngine = vimEngine
        textView.isRichText = false
        textView.allowsUndo = true
        let defaultFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.font = defaultFont
        textView.baseFont = defaultFont
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.backgroundColor = .clear
        textView.textColor = NSColor(theme.foreground)
        textView.delegate = context.coordinator
        textView.string = content

        // Setup Engine Callbacks
        vimEngine.onTextChange = { newText in
            if textView.string != newText {
                textView.string = newText
                self.content = newText
                if settings.isSyntaxHighlightingEnabled {
                    textView.highlightSyntax(with: theme)
                }
            }
        }
        
        vimEngine.onSelectionChange = { newRange in
            if textView.selectedRange() != newRange {
                textView.setSelectedRange(newRange)
                textView.scrollToVisible(textView.firstRect(forCharacterRange: newRange, actualRange: nil))
            }
            // Refresh line numbers on selection change if relative
            if settings.isRelativeLineNumbersEnabled {
                textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
            }
        }

        vimEngine.onUndo = {
            textView.undoManager?.undo()
        }

        scrollView.documentView = textView
        
        // Setup Line Numbers
        scrollView.rulersVisible = true
        scrollView.drawsBackground = false
        let ruler = LineNumberRulerView(textView: textView, settings: settings, theme: theme)
        scrollView.verticalRulerView = ruler
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? EditorTextView {
            if textView.string != content {
                textView.string = content
                if settings.isSyntaxHighlightingEnabled {
                    textView.highlightSyntax(with: theme)
                }
            }
            
            textView.vimEngine = vimEngine
            
            // Only update colors if theme changed
            let nsThemeForeground = NSColor(theme.foreground)
            if textView.textColor != nsThemeForeground {
                textView.textColor = nsThemeForeground
                textView.insertionPointColor = NSColor(theme.accent)
                if settings.isSyntaxHighlightingEnabled {
                    textView.highlightSyntax(with: theme)
                }
            }
            
            if !settings.isSyntaxHighlightingEnabled && textView.textStorage?.length ?? 0 > 0 {
                textView.textStorage?.setAttributes([.foregroundColor: NSColor(theme.foreground), .font: textView.baseFont], range: NSRange(location: 0, length: textView.string.count))
            }
            
            nsView.rulersVisible = settings.isRelativeLineNumbersEnabled
            if let ruler = nsView.verticalRulerView as? LineNumberRulerView {
                ruler.theme = theme
                ruler.needsDisplay = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorContainerView

        init(_ parent: EditorContainerView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? EditorTextView {
                if self.parent.content != textView.string {
                    self.parent.content = textView.string
                    if self.parent.settings.isSyntaxHighlightingEnabled {
                        textView.highlightSyntax(with: self.parent.theme)
                    }
                }
            }
        }
    }
}

class EditorTextView: NSTextView {
    var vimEngine: VimEngine?
    var baseFont: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    func highlightSyntax(with theme: AppTheme) {
        guard let storage = textStorage else { return }
        let text = storage.string
        let fullRange = NSRange(location: 0, length: text.count)
        if fullRange.length == 0 { return }
        
        storage.beginEditing()
        storage.setAttributes([.foregroundColor: NSColor(theme.foreground), .font: baseFont], range: fullRange)
        
        let patterns: [(String, NSColor)] = [
            ("^# .*", NSColor(theme.h1)),
            ("^## .*", NSColor(theme.h2)),
            ("^### .*", NSColor(theme.h3)),
            ("\\*\\*.*?\\*\\*", NSColor(theme.accent)), // Bold
            ("\\*.*?\\*", NSColor(theme.accent).withAlphaComponent(0.8)), // Italic
            ("`.*?`", NSColor(theme.foreground).withAlphaComponent(0.7)) // Inline code
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        storage.addAttribute(.foregroundColor, value: color, range: range)
                        if pattern.contains("#") {
                            storage.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: baseFont.pointSize + 2), range: range)
                        }
                    }
                }
            }
        }
        storage.endEditing()
    }

    override func keyDown(with event: NSEvent) {
        guard let engine = vimEngine else {
            super.keyDown(with: event)
            return
        }
        
        if let vimKey = VimKeyMapper.string(from: event) {
            if engine.mode != .insert || vimKey == "<Esc>" {
                engine.handleInput(vimKey, currentText: self.string, currentSelection: self.selectedRange())
                return
            }
        }
        
        super.keyDown(with: event)
    }
}

class LineNumberRulerView: NSRulerView {
    var settings: SettingsManager
    var theme: AppTheme
    
    init(textView: NSTextView, settings: SettingsManager, theme: AppTheme) {
        self.settings = settings
        self.theme = theme
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let visibleRect = textView.visibleRect
        let range = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let fullText = textView.string as NSString
        if fullText.length == 0 { return }
        
        let firstLineRange = fullText.lineRange(for: NSRange(location: range.location, length: 0))
        
        var glyphIndex = range.location
        var lineCount = 0
        
        // Find actual line number of first visible glyph
        let prefix = fullText.substring(to: firstLineRange.location)
        let currentLineNumber = prefix.components(separatedBy: "\n").count
        
        // For relative line numbers, we need the cursor line
        let cursorLocation = textView.selectedRange().location
        let cursorLineNumber = fullText.substring(to: min(fullText.length, cursorLocation)).components(separatedBy: "\n").count

        while glyphIndex < NSMaxRange(range) {
            let lineRange = fullText.lineRange(for: NSRange(location: glyphIndex, length: 0))
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            
            let y = lineRect.origin.y + textView.textContainerInset.height - visibleRect.origin.y
            
            let displayNum: Int
            let isCursorLine = currentLineNumber + lineCount == cursorLineNumber
            
            if settings.isRelativeLineNumbersEnabled {
                displayNum = isCursorLine ? cursorLineNumber : abs((currentLineNumber + lineCount) - cursorLineNumber)
            } else {
                displayNum = currentLineNumber + lineCount
            }
            
            let label = "\(displayNum)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10),
                .foregroundColor: isCursorLine ? NSColor(theme.accent) : NSColor.secondaryLabelColor
            ]
            
            let labelSize = label.size(withAttributes: attributes)
            label.draw(at: NSPoint(x: ruleThickness - labelSize.width - 5, y: y + (lineRect.height - labelSize.height) / 2), withAttributes: attributes)
            
            glyphIndex = NSMaxRange(lineRange)
            lineCount += 1
        }
    }
}
