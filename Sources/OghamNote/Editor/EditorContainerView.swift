import SwiftUI
import AppKit

struct EditorContainerView: NSViewRepresentable {
    @Binding var content: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let textView = EditorTextView(frame: .zero)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.backgroundColor = .clear
        textView.textColor = .labelColor
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? EditorTextView, textView.string != content {
            textView.string = content
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
            if let textView = notification.object as? NSTextView {
                self.parent.content = textView.string
            }
        }
    }
}

class EditorTextView: NSTextView {
    override func drawBackground(in rect: NSRect) {
        // Transparent background handled by parent visual effect view
    }
}
