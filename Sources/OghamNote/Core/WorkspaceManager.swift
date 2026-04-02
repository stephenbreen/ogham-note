import Foundation
import AppKit
import SwiftUI

@MainActor
class WorkspaceManager: ObservableObject {
    @Published var rootItems: [FileItem] = []
    @Published var selectedFileURL: URL?
    @Published var currentWorkspaceURL: URL?
    @Published var recentNotes: [FileItem] = []

    private let maxRecentNotes = 10

    func selectWorkspace() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Open Workspace"

        if openPanel.runModal() == .OK, let url = openPanel.url {
            self.currentWorkspaceURL = url
            self.refresh()
        }
    }

    func refresh() {
        guard let url = currentWorkspaceURL else { return }
        self.rootItems = scanDirectory(at: url)
    }

    private func scanDirectory(at url: URL) -> [FileItem] {
        let fileManager = FileManager.default
        do {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles])
            
            return contents.map { fileURL -> FileItem in
                let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys))
                let isDirectory = resourceValues?.isDirectory ?? false
                
                var children: [FileItem]? = nil
                if isDirectory {
                    children = scanDirectory(at: fileURL)
                }
                
                return FileItem(url: fileURL, isDirectory: isDirectory, children: children)
            }.sorted { (a, b) -> Bool in
                if a.isDirectory != b.isDirectory {
                    return a.isDirectory // Folders first
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
        } catch {
            print("Error scanning directory \(url): \(error)")
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
