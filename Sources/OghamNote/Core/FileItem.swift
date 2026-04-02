import Foundation

struct FileItem: Identifiable, Hashable {
    var id: String { url.path }
    let url: URL
    let isDirectory: Bool
    var children: [FileItem]?

    var name: String {
        url.lastPathComponent
    }

    var icon: String {
        if isDirectory {
            return "folder"
        } else {
            return "doc.text"
        }
    }
}
