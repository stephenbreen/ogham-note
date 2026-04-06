import Foundation
import AppKit
import SwiftUI

@MainActor
class WorkspaceManager: ObservableObject {
    @Published var rootItems: [FileItem] = []
    @Published var selectedFileURL: URL?
    @Published var currentWorkspaceURL: URL?
    @Published var recentNotes: [FileItem] = []
    @Published var isScanning = false

    private let maxRecentNotes = 10
    private var ignoredPatterns: [String] = [".git", "node_modules", ".build", ".swiftpm"]

    func selectWorkspace() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Open Workspace"

        if openPanel.runModal() == .OK, let url = openPanel.url {
            self.currentWorkspaceURL = url
            Task {
                await self.refresh()
            }
        }
    }

    func refresh() async {
        guard let url = currentWorkspaceURL else { return }
        isScanning = true
        
        // Load .gitignore if present
        loadGitIgnore(from: url)
        
        let currentPatterns = self.ignoredPatterns
        let items = await Task.detached(priority: .userInitiated) {
            return self.scanDirectory(at: url, ignoredPatterns: currentPatterns)
        }.value
        
        self.rootItems = items
        isScanning = false
    }

    private func loadGitIgnore(from workspaceURL: URL) {
        let gitIgnoreURL = workspaceURL.appendingPathComponent(".gitignore")
        if let content = try? String(contentsOf: gitIgnoreURL) {
            let patterns = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            self.ignoredPatterns.append(contentsOf: patterns)
        }
    }

    private nonisolated func scanDirectory(at url: URL, ignoredPatterns: [String]) -> [FileItem] {
        let fileManager = FileManager.default
        do {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles])
            
            return contents.compactMap { fileURL -> FileItem? in
                let name = fileURL.lastPathComponent
                
                // Skip ignored patterns
                if ignoredPatterns.contains(where: { pattern in
                    if pattern.contains("*") {
                        // Simple glob-like matching
                        let regex = try? NSRegularExpression(pattern: pattern.replacingOccurrences(of: "*", with: ".*"))
                        return regex?.firstMatch(in: name, range: NSRange(location: 0, length: name.count)) != nil
                    }
                    return name == pattern || pattern == "\(name)/"
                }) {
                    return nil
                }

                let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys))
                let isDirectory = resourceValues?.isDirectory ?? false
                
                var children: [FileItem]? = nil
                if isDirectory {
                    children = scanDirectory(at: fileURL, ignoredPatterns: ignoredPatterns)
                }
                
                return FileItem(url: fileURL, isDirectory: isDirectory, children: children)
            }.sorted { (a, b) -> Bool in
                if a.isDirectory != b.isDirectory {
                    return a.isDirectory // Folders first
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
        } catch {
            return []
        }
    }

    func openFile(_ item: FileItem) {
        if !item.isDirectory {
            self.selectedFileURL = item.url
            addToRecent(item)
        }
    }

    private func addToRecent(_ item: FileItem) {
        if let index = recentNotes.firstIndex(where: { $0.url == item.url }) {
            recentNotes.remove(at: index)
        }
        recentNotes.insert(item, at: 0)
        if recentNotes.count > maxRecentNotes {
            recentNotes.removeLast()
        }
    }
}
