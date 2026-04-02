import SwiftUI
import Markdown

struct MarkdownPreviewView: View {
    let content: String
    let theme: AppTheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if content.isEmpty {
                    SwiftUI.Text("No content to preview")
                        .foregroundColor(.secondary)
                } else {
                    MarkdownRendererView(text: content, theme: theme)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MarkdownRendererView: View {
    let text: String
    let theme: AppTheme
    
    var body: some View {
        let document = Document(parsing: text)
        var renderer = SwiftUIWalker(theme: theme)
        return renderer.visit(document)
    }
}

// A simple recursive walker to build a SwiftUI view tree from the Markdown AST
struct SwiftUIWalker: MarkupVisitor {
    let theme: AppTheme
    
    // The result of the visit is an AnyView containing the rendered content
    typealias Result = AnyView
    
    mutating func defaultVisit(_ markup: Markup) -> AnyView {
        let views = markup.children.map { visit($0) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                ForEach(0..<views.count, id: \.self) { i in
                    views[i]
                }
            }
        )
    }
    
    mutating func visitText(_ text: Markdown.Text) -> AnyView {
        AnyView(SwiftUI.Text(text.string).foregroundColor(theme.foreground))
    }
    
    mutating func visitHeading(_ heading: Heading) -> AnyView {
        let views = heading.children.map { visit($0) }
        let fontSize: CGFloat = switch heading.level {
        case 1: 28
        case 2: 24
        case 3: 20
        default: 18
        }
        
        let headerColor = switch heading.level {
        case 1: theme.h1
        case 2: theme.h2
        case 3: theme.h3
        default: theme.h3
        }
        
        return AnyView(
            HStack(spacing: 0) {
                ForEach(0..<views.count, id: \.self) { i in
                    views[i]
                }
            }
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(headerColor)
            .padding(.top, 10)
        )
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> AnyView {
        AnyView(
            SwiftUI.Text(codeBlock.code)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(theme.foreground)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.codeBackground)
                .cornerRadius(4)
        )
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) -> AnyView {
        let views = paragraph.children.map { visit($0) }
        return AnyView(
            HStack(spacing: 0) {
                ForEach(0..<views.count, id: \.self) { i in
                    views[i]
                }
            }
        )
    }
    
    mutating func visitStrong(_ strong: Markdown.Strong) -> AnyView {
        let views = strong.children.map { visit($0) }
        return AnyView(
            HStack(spacing: 0) {
                ForEach(0..<views.count, id: \.self) { i in
                    views[i].bold()
                }
            }
        )
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) -> AnyView {
        let views = emphasis.children.map { visit($0) }
        return AnyView(
            HStack(spacing: 0) {
                ForEach(0..<views.count, id: \.self) { i in
                    views[i].italic()
                }
            }
        )
    }
}
