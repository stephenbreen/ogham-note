import SwiftUI
import AppKit
import Markdown

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

        vimEngine.onInsertModeStarted = {
            textView.undoManager?.beginUndoGrouping()
        }

        vimEngine.onInsertModeEnded = {
            textView.undoManager?.endUndoGrouping()
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
        guard let storage = textStorage, let layoutManager = layoutManager, let textContainer = textContainer else { return }
        
        let visibleRect = visibleRect
        let visibleRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: visibleRange, actualGlyphRange: nil)
        
        if characterRange.length == 0 { return }
        
        // Use the FULL text for now to simplify range mapping, but we could optimize to only parse the visible block.
        // Even with 10k lines, parsing the full document once is usually <50ms.
        var highlighter = MarkdownHighlighter(storage: storage, theme: theme, baseFont: baseFont)
        
        storage.beginEditing()
        // Reset ALL attributes to base first (O(N) unfortunately, but needed for consistency)
        // Optimization: Reset only the visible range?
        storage.setAttributes([.foregroundColor: NSColor(theme.foreground), .font: baseFont], range: NSRange(location: 0, length: storage.string.count))
        
        // Perform AST-based highlighting
        let document = Document(parsing: storage.string)
        highlighter.visit(document)
        
        storage.endEditing()
    }

    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        guard let engine = vimEngine, flag else {
            super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
            return
        }
        
        switch engine.mode {
        case .normal, .visual, .visualLine:
            // Draw a block cursor
            let selectedRange = self.selectedRange()
            let range = NSRange(location: selectedRange.location, length: 1)
            let safeRange = NSRange(location: selectedRange.location, length: min(1, self.string.count - selectedRange.location))
            
            var blockRect = rect
            if safeRange.length > 0 {
                blockRect = self.firstRect(forCharacterRange: safeRange, actualRange: nil)
                blockRect = self.convert(blockRect, from: nil)
            } else {
                // At end of buffer, draw a standard-width block
                blockRect.size.width = 8
            }
            
            color.withAlphaComponent(0.6).set()
            blockRect.fill()
            
        case .insert:
            super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
            
        case .command, .search:
            // Hide editor cursor as focus is in command bar
            break
        }
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
                displayNum = isCursorLine ? (currentLineNumber + lineCount) : abs((currentLineNumber + lineCount) - cursorLineNumber)
            } else {
                displayNum = currentLineNumber + lineCount
            }
            
            let label = "\(displayNum)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: isCursorLine ? .bold : .regular),
                .foregroundColor: isCursorLine ? NSColor(theme.accent) : NSColor.secondaryLabelColor
            ]
            
            let labelSize = label.size(withAttributes: attributes)
            label.draw(at: NSPoint(x: ruleThickness - labelSize.width - 5, y: y + (lineRect.height - labelSize.height) / 2), withAttributes: attributes)
            
            glyphIndex = NSMaxRange(lineRange)
            lineCount += 1
        }
    }
}
