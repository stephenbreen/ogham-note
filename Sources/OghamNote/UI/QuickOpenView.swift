import SwiftUI

struct QuickOpenView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    let theme: AppTheme
    @Binding var isVisible: Bool
    
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    @State private var selectedIndex = 0
    
    var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return workspaceManager.allFileItems.prefix(10).map { $0 }
        }
        
        // Simple fuzzy match: characters must appear in order
        return workspaceManager.allFileItems.filter { item in
            let name = item.name.lowercased()
            let query = searchText.lowercased()
            
            var queryIdx = query.startIndex
            for char in name {
                if queryIdx == query.endIndex { break }
                if char == query[queryIdx] {
                    queryIdx = query.index(after: queryIdx)
                }
            }
            return queryIdx == query.endIndex
        }.sorted { a, b in
            // Prioritize matches that start with the query
            let aStarts = a.name.lowercased().hasPrefix(searchText.lowercased())
            let bStarts = b.name.lowercased().hasPrefix(searchText.lowercased())
            if aStarts != bStarts { return aStarts }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search files...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .onSubmit {
                        openSelected()
                    }
            }
            .padding()
            .background(Color.black.opacity(0.05))
            
            // Results
            ScrollViewReader { proxy in
                List(Array(filteredFiles.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(theme.accent)
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .fontWeight(index == selectedIndex ? .bold : .regular)
                            Text(item.url.path(percentEncoded: false))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(index == selectedIndex ? theme.accent.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .onTapGesture {
                        selectedIndex = index
                        openSelected()
                    }
                    .id(item.id)
                }
                .listStyle(.plain)
                .frame(maxHeight: 300)
                .onChange(of: selectedIndex) { _, newIdx in
                    if newIdx < filteredFiles.count {
                        proxy.scrollTo(filteredFiles[newIdx].id)
                    }
                }
            }
        }
        .frame(width: 500)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(radius: 20)
        .onAppear {
            isFocused = true
        }
        .onKeyPress(.downArrow) {
            selectedIndex = min(filteredFiles.count - 1, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.escape) {
            isVisible = false
            return .handled
        }
        .onChange(of: searchText) {
            selectedIndex = 0
        }
    }
    
    private func openSelected() {
        let files = filteredFiles
        guard selectedIndex < files.count else { return }
        workspaceManager.selectedFileURL = files[selectedIndex].url
        isVisible = false
    }
}
