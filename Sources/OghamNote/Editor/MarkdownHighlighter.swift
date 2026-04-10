import AppKit
import Markdown

import AppKit
import Markdown

struct MarkdownHighlighter: MarkupVisitor {
    typealias Result = Void
    
    private let storage: NSTextStorage
    private let theme: AppTheme
    private let baseFont: NSFont
    private let text: String
    
    init(storage: NSTextStorage, theme: AppTheme, baseFont: NSFont) {
        self.storage = storage
        self.theme = theme
        self.baseFont = baseFont
        self.text = storage.string
    }
    
    mutating func defaultVisit(_ markup: Markup) {
        for child in markup.children {
            visit(child)
        }
    }
    
    // MARK: - Visitor Methods
    
    mutating func visitHeading(_ heading: Heading) {
        applyAttributes(for: heading) {
            let fontSize = switch heading.level {
            case 1: baseFont.pointSize + 8
            case 2: baseFont.pointSize + 4
            case 3: baseFont.pointSize + 2
            default: baseFont.pointSize
            }
            
            let color = switch heading.level {
            case 1: theme.h1
            case 2: theme.h2
            case 3: theme.h3
            default: theme.foreground
            }
            
            return [
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor(color)
            ]
        }
        defaultVisit(heading)
    }
    
    mutating func visitStrong(_ strong: Strong) {
        applyAttributes(for: strong) {
            return [
                .font: NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask),
                .foregroundColor: NSColor(theme.accent)
            ]
        }
        defaultVisit(strong)
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        applyAttributes(for: emphasis) {
            return [
                .font: NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
            ]
        }
        defaultVisit(emphasis)
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        applyAttributes(for: inlineCode) {
            return [
                .font: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular),
                .foregroundColor: NSColor(theme.foreground).withAlphaComponent(0.8),
                .backgroundColor: NSColor(theme.codeBackground).withAlphaComponent(0.3)
            ]
        }
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        applyAttributes(for: codeBlock) {
            return [
                .font: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular),
                .backgroundColor: NSColor(theme.codeBackground).withAlphaComponent(0.2)
            ]
        }
    }
    
    mutating func visitLink(_ link: Link) {
        applyAttributes(for: link) {
            return [
                .foregroundColor: NSColor(theme.link),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        }
        defaultVisit(link)
    }
    
    // MARK: - Helper
    
    private func applyAttributes(for markup: Markup, attributesProvider: () -> [NSAttributedString.Key: Any]) {
        guard let range = markup.range else { return }
        let nsRange = calculateNSRange(from: range)
        storage.addAttributes(attributesProvider(), range: nsRange)
    }
    
    private func calculateNSRange(from sourceRange: SourceRange) -> NSRange {
        let lines = text.components(separatedBy: .newlines)
        var offset = 0
        
        // Calculate offset for the start line
        for i in 0..<(sourceRange.lowerBound.line - 1) {
            offset += lines[i].count + 1 // +1 for newline
        }
        
        let start = offset + (sourceRange.lowerBound.column - 1)
        
        var endOffset = 0
        for i in 0..<(sourceRange.upperBound.line - 1) {
            endOffset += lines[i].count + 1
        }
        let end = endOffset + (sourceRange.upperBound.column - 1)
        
        return NSRange(location: start, length: max(0, end - start))
    }
}
