import Foundation

struct SearchResult: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let lineNumber: Int
    let content: String
    
    init(url: URL, lineNumber: Int, content: String) {
        self.id = UUID()
        self.url = url
        self.lineNumber = lineNumber
        self.content = content
    }
    
    var fileName: String {
        url.lastPathComponent
    }
}

@MainActor
class SearchManager: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchText = ""
    
    func performSearch(in workspaceURL: URL?) {
        guard let url = workspaceURL, !searchText.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        results = []
        let query = searchText
        
        // Run search in background to not block UI
        Task.detached(priority: .userInitiated) {
            let matches = self.searchDirectory(at: url, query: query)
            
            await MainActor.run {
                self.results = matches
                self.isSearching = false
            }
        }
    }
    
    nonisolated private func searchDirectory(at url: URL, query: String) -> [SearchResult] {
        var matches: [SearchResult] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            // Only search markdown files
            guard fileURL.pathExtension == "md" else { continue }
            
            if let content = try? String(contentsOf: fileURL) {
                let lines = content.components(separatedBy: .newlines)
                for (index, line) in lines.enumerated() {
                    if line.localizedCaseInsensitiveContains(query) {
                        matches.append(SearchResult(url: fileURL, lineNumber: index + 1, content: line.trimmingCharacters(in: .whitespaces)))
                    }
                }
            }
        }
        
        return matches
    }
}
