import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    @AppStorage("isSyntaxHighlightingEnabled") var isSyntaxHighlightingEnabled: Bool = true
    @AppStorage("isRelativeLineNumbersEnabled") var isRelativeLineNumbersEnabled: Bool = true
}
