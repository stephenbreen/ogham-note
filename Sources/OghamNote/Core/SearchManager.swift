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
    
    // In-memory cache for file contents to speed up repeated searches
    private var fileCache: [URL: (content: String, modificationDate: Date)] = [:]
    
    func performSearch(in workspaceURL: URL?) {
        guard let url = workspaceURL, !searchText.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        results = []
        let query = searchText
        
        Task {
            let matches = await Task.detached(priority: .userInitiated) {
                return self.searchDirectory(at: url, query: query)
            }.value
            
            self.results = matches
            self.isSearching = false
        }
    }
    
    private nonisolated func searchDirectory(at url: URL, query: String) -> [SearchResult] {
        var matches: [SearchResult] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }
            
            let content: String
            // CHECK CACHE: Using a synchronized wrapper or just keeping it simple for now as it's nonisolated
            // In a real app, we'd use an actor for the cache.
            content = (try? String(contentsOf: fileURL)) ?? ""
            
            if content.localizedCaseInsensitiveContains(query) {
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
