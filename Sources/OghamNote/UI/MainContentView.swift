import SwiftUI

struct MainContentView: View {
    @State private var isSidebarVisible = true
    @State private var isPreviewVisible = false
    @State private var content: String = "# Welcome to Ogham Note\n\nStart editing your markdown files with Vim keybindings."

    var body: some View {
        NavigationSplitView {
            if isSidebarVisible {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 400)
            }
        } detail: {
            HSplitView {
                EditorContainerView(content: $content)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if isPreviewVisible {
                    MarkdownPreviewView(content: content)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { isSidebarVisible.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")
            }
            ToolbarItem(placement: .status) {
                Button(action: { isPreviewVisible.toggle() }) {
                    Image(systemName: isPreviewVisible ? "eye.fill" : "eye")
                }
                .help("Toggle Preview")
            }
        }
    }
}

struct SidebarView: View {
    var body: some View {
        List {
            Section("Workspace") {
                Label("README.md", systemImage: "doc.text")
                Label("Notes", systemImage: "folder")
            }
        }
        .listStyle(.sidebar)
    }
}

struct MarkdownPreviewView: View {
    let content: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(content) // Placeholder for cmark rendering
                    .padding()
            }
        }
    }
}
