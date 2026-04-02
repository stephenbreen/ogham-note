import SwiftUI

struct MainContentView: View {
    @StateObject private var vimEngine = VimEngine()
    @StateObject private var workspaceManager = WorkspaceManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var searchManager = SearchManager()
    @StateObject private var settingsManager = SettingsManager()
    
    @State private var isSidebarVisible = true
    @State private var isPreviewVisible = false
    @State private var isDistractionFree = false
    @State private var content: String = "# Welcome to Ogham Note\n\nStart editing your markdown files with Vim keybindings."

    var body: some View {
        NavigationSplitView {
            if isSidebarVisible && !isDistractionFree {
                SidebarView(
                    workspaceManager: workspaceManager,
                    searchManager: searchManager,
                    theme: themeManager.currentTheme
                )
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 400)
            }
        } detail: {
            VStack(spacing: 0) {
                HSplitView {
                    EditorContainerView(
                        content: $content, 
                        vimEngine: vimEngine, 
                        theme: themeManager.currentTheme,
                        settings: settingsManager
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Ensure the editor itself is not animated by global state changes
                    .animation(nil, value: content)

                    if isPreviewVisible {
                        MarkdownPreviewView(content: content, theme: themeManager.currentTheme)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(themeManager.currentTheme.background.opacity(0.8))
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    }
                }

                if !isDistractionFree {
                    StatusBarView(vimEngine: vimEngine, theme: themeManager.currentTheme)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            // Scope animations to only the layout toggles
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPreviewVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isDistractionFree)
        }
        .onChange(of: workspaceManager.selectedFileURL) { oldVal, newVal in
            if let url = newVal {
                if let fileContent = try? String(contentsOf: url) {
                    // Quick fade for file changes is fine
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.content = fileContent
                    }
                    vimEngine.setBuffer(fileContent)
                }
            }
        }
        .sheet(isPresented: $vimEngine.showHelp) {
            HelpView(theme: themeManager.currentTheme, isPresented: $vimEngine.showHelp)
        }
        .toolbar {
            // REDUCED: Removed manual sidebar toggle. NavigationSplitView handles this natively.
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { workspaceManager.selectWorkspace() }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("Open Workspace Folder")
                
                Button(action: { 
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isDistractionFree.toggle() 
                    }
                }) {
                    Image(systemName: isDistractionFree ? "leaf.fill" : "leaf")
                        .foregroundColor(isDistractionFree ? themeManager.currentTheme.accent : .primary)
                }
                .help("Toggle Distraction Free Mode")
            }
            
            ToolbarItemGroup(placement: .status) {
                Menu {
                    Section("Theme") {
                        Button("Nord") { withAnimation { themeManager.setTheme(.nord) } }
                        Button("Dracula") { withAnimation { themeManager.setTheme(.dracula) } }
                        Button("Gruvbox") { withAnimation { themeManager.setTheme(.gruvbox) } }
                        Button("Monokai") { withAnimation { themeManager.setTheme(.monokai) } }
                    }
                    
                    Section("Editor") {
                        Toggle("Syntax Highlighting", isOn: $settingsManager.isSyntaxHighlightingEnabled)
                        Toggle("Relative Line Numbers", isOn: $settingsManager.isRelativeLineNumbersEnabled)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .help("Settings")
                
                Button(action: { 
                    withAnimation(.spring()) {
                        isPreviewVisible.toggle() 
                    }
                }) {
                    Image(systemName: isPreviewVisible ? "eye.fill" : "eye")
                        .foregroundColor(isPreviewVisible ? themeManager.currentTheme.accent : .primary)
                }
                .help("Toggle Preview")
            }
        }
    }
}

struct SidebarView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    @ObservedObject var searchManager: SearchManager
    let theme: AppTheme
    @State private var hoveredID: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Top-Level Search Interface
            TextField("Search notes...", text: $searchManager.searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onSubmit {
                    withAnimation {
                        searchManager.performSearch(in: workspaceManager.currentWorkspaceURL)
                    }
                }

            List {
                if !searchManager.results.isEmpty {
                    Section("Search Results") {
                        ForEach(searchManager.results) { result in
                            SearchResultRow(result: result, theme: theme) {
                                workspaceManager.selectedFileURL = result.url
                            }
                        }
                    }
                }

                // 2. Recent Notes List
                if !workspaceManager.recentNotes.isEmpty {
                    Section("Recent Notes") {
                        ForEach(workspaceManager.recentNotes) { item in
                            FileRow(item: item, isSelected: workspaceManager.selectedFileURL == item.url, theme: theme) {
                                workspaceManager.openFile(item)
                            }
                        }
                    }
                }

                // 3. Workspaces Section
                Section("Workspaces") {
                    WorkspaceRow(name: "Personal", icon: "personalhotspot", theme: theme)
                    WorkspaceRow(name: "Professional", icon: "briefcase.fill", theme: theme)
                    WorkspaceRow(name: "Ideas/Drafts", icon: "sparkles", theme: theme)
                }

                Section("All Files") {
                    if workspaceManager.rootItems.isEmpty {
                        Text("No folder open")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        OutlineGroup(workspaceManager.rootItems, children: \.children) { item in
                            FileRow(item: item, isSelected: workspaceManager.selectedFileURL == item.url, theme: theme) {
                                workspaceManager.openFile(item)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.fileName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.accent)
                Text(result.content)
                    .font(.system(size: 10, design: .monospaced))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FileRow: View {
    let item: FileItem
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(item.name, systemImage: item.icon)
                .foregroundColor(isSelected ? theme.accent : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct WorkspaceRow: View {
    let name: String
    let icon: String
    let theme: AppTheme
    
    var body: some View {
        Label(name, systemImage: icon)
            .foregroundColor(.primary)
    }
}

struct StatusBarView: View {
    @ObservedObject var vimEngine: VimEngine
    let theme: AppTheme

    var body: some View {
        HStack {
            Text(vimEngine.mode.rawValue)
                .font(.caption)
                .fontWeight(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(modeColor)
                .foregroundColor(.white)
                .cornerRadius(4)
                .animation(.spring(), value: vimEngine.mode)

            if !vimEngine.commandText.isEmpty {
                Text(vimEngine.commandText)
                    .font(.caption)
                    .padding(.leading, 8)
                    .foregroundColor(theme.foreground)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(VisualEffectView(material: .contentBackground, blendingMode: .withinWindow))
    }

    var modeColor: Color {
        switch vimEngine.mode {
        case .normal: return theme.normalMode
        case .insert: return theme.insertMode
        case .visual, .visualLine: return theme.visualMode
        case .command: return theme.commandMode
        }
    }
}
