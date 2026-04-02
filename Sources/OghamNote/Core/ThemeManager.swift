import SwiftUI

struct AppTheme: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    
    // Core Colors
    let background: Color
    let foreground: Color
    let accent: Color
    let secondaryBackground: Color
    
    // Vim Mode Colors
    let normalMode: Color
    let insertMode: Color
    let visualMode: Color
    let commandMode: Color
    
    // Markdown Colors
    let h1: Color
    let h2: Color
    let h3: Color
    let link: Color
    let codeBackground: Color
    
    static let nord = AppTheme(
        id: "nord",
        name: "Nord",
        background: Color(red: 0.18, green: 0.20, blue: 0.25), // #2e3440
        foreground: Color(red: 0.85, green: 0.87, blue: 0.91), // #d8dee9
        accent: Color(red: 0.53, green: 0.71, blue: 0.90),     // #88c0d0
        secondaryBackground: Color(red: 0.23, green: 0.26, blue: 0.32), // #3b4252
        normalMode: Color(red: 0.49, green: 0.63, blue: 0.83), // #81a1c1
        insertMode: Color(red: 0.64, green: 0.75, blue: 0.55), // #a3be8c
        visualMode: Color(red: 0.81, green: 0.54, blue: 0.41), // #d08770
        commandMode: Color(red: 0.71, green: 0.56, blue: 0.68), // #b48ead
        h1: Color(red: 0.53, green: 0.71, blue: 0.90), // #88c0d0
        h2: Color(red: 0.51, green: 0.63, blue: 0.76), // #81a1c1
        h3: Color(red: 0.37, green: 0.51, blue: 0.67), // #5e81ac
        link: Color(red: 0.53, green: 0.71, blue: 0.90),
        codeBackground: Color(red: 0.23, green: 0.26, blue: 0.32)
    )
    
    static let dracula = AppTheme(
        id: "dracula",
        name: "Dracula",
        background: Color(red: 0.16, green: 0.16, blue: 0.21), // #282a36
        foreground: Color(red: 0.97, green: 0.97, blue: 0.95), // #f8f8f2
        accent: Color(red: 0.74, green: 0.58, blue: 0.95),     // #bd93f9
        secondaryBackground: Color(red: 0.26, green: 0.28, blue: 0.35), // #44475a
        normalMode: Color(red: 0.38, green: 0.51, blue: 0.98),
        insertMode: Color(red: 0.31, green: 0.98, blue: 0.48), // #50fa7b
        visualMode: Color(red: 1.0, green: 0.72, blue: 0.42),  // #ffb86c
        commandMode: Color(red: 1.0, green: 0.48, blue: 0.77), // #ff79c6
        h1: Color(red: 0.74, green: 0.58, blue: 0.95), // #bd93f9
        h2: Color(red: 1.0, green: 0.48, blue: 0.77),  // #ff79c6
        h3: Color(red: 0.55, green: 0.91, blue: 0.99),  // #8be9fd
        link: Color(red: 0.55, green: 0.91, blue: 0.99),
        codeBackground: Color(red: 0.26, green: 0.28, blue: 0.35)
    )

    static let gruvbox = AppTheme(
        id: "gruvbox",
        name: "Gruvbox",
        background: Color(red: 0.16, green: 0.16, blue: 0.16), // #282828
        foreground: Color(red: 0.92, green: 0.86, blue: 0.70), // #ebdbb2
        accent: Color(red: 0.98, green: 0.30, blue: 0.24),     // #fb4934
        secondaryBackground: Color(red: 0.20, green: 0.20, blue: 0.20), // #32302f
        normalMode: Color(red: 0.51, green: 0.65, blue: 0.60), // #83a598
        insertMode: Color(red: 0.72, green: 0.73, blue: 0.15), // #b8bb26
        visualMode: Color(red: 0.98, green: 0.74, blue: 0.18), // #fabd2f
        commandMode: Color(red: 0.83, green: 0.52, blue: 0.61), // #d3869b
        h1: Color(red: 0.72, green: 0.73, blue: 0.15), // #b8bb26
        h2: Color(red: 0.98, green: 0.74, blue: 0.18), // #fabd2f
        h3: Color(red: 0.51, green: 0.65, blue: 0.60), // #83a598
        link: Color(red: 0.51, green: 0.65, blue: 0.60),
        codeBackground: Color(red: 0.24, green: 0.22, blue: 0.21) // #3c3836
    )

    static let monokai = AppTheme(
        id: "monokai",
        name: "Monokai",
        background: Color(red: 0.15, green: 0.16, blue: 0.13), // #272822
        foreground: Color(red: 0.97, green: 0.97, blue: 0.95), // #f8f8f2
        accent: Color(red: 0.40, green: 0.85, blue: 0.94),     // #66d9ef
        secondaryBackground: Color(red: 0.23, green: 0.23, blue: 0.20), // #3e3d32
        normalMode: Color(red: 0.40, green: 0.85, blue: 0.94), // #66d9ef
        insertMode: Color(red: 0.65, green: 0.89, blue: 0.18), // #a6e22e
        visualMode: Color(red: 0.99, green: 0.59, blue: 0.12), // #fd971f
        commandMode: Color(red: 0.98, green: 0.15, blue: 0.45), // #f92672
        h1: Color(red: 0.98, green: 0.15, blue: 0.45), // #f92672
        h2: Color(red: 0.65, green: 0.89, blue: 0.18), // #a6e22e
        h3: Color(red: 0.99, green: 0.59, blue: 0.12), // #fd971f
        link: Color(red: 0.40, green: 0.85, blue: 0.94),
        codeBackground: Color(red: 0.23, green: 0.23, blue: 0.20)
    )
    
    static func from(id: String) -> AppTheme {
        switch id {
        case "dracula": return .dracula
        case "gruvbox": return .gruvbox
        case "monokai": return .monokai
        default: return .nord
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    
    private let themeKey = "selected_theme_id"
    
    init() {
        let savedId = UserDefaults.standard.string(forKey: themeKey) ?? "nord"
        self.currentTheme = AppTheme.from(id: savedId)
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.id, forKey: themeKey)
    }
}
