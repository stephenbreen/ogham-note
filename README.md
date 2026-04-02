# Ogham Note

**Ogham Note** is a high-performance, native macOS Markdown editor designed for users who demand the speed of Vim and the elegance of a minimalist desktop application. Built with **Swift 6**, **SwiftUI**, and a native **Vim engine**, it offers a near-zero latency typing experience and an authentic Vim-like editing environment.

## Key Features

- **Native Performance:** Avoids the overhead of Electron-based editors by using a pure Swift/AppKit core.
- **Vim-Lite Engine:** Authentic modal editing (Normal, Insert, Visual, Command) with standard Vim motions and operators.
- **Minimalist Workspace:** A distraction-free, "glassmorphic" interface with a toggleable sidebar for folder-based navigation.
- **Markdown Preview:** Integrated Markdown rendering for a live view of your notes.
- **Modern macOS Design:** Adheres to Apple's design principles with SF Mono typography and system vibrancy.

## Architectural Principles

- **Native First:** Prioritizes native AppKit/SwiftUI components over web abstractions.
- **Vim Integrity:** A custom Vim engine manages modal logic and buffer state, while `NSTextView` provides high-performance rendering.
- **Minimalism:** No toolbars or heavy menus; every UI element is functional and mode-aware.

## Technical Stack

- **Swift 6** & **SwiftUI**
- **libvim.swift:** Swift wrapper for a core Vim engine.
- **swift-markdown:** Apple's official Markdown parsing library.
- **AppKit:** For high-performance `NSTextView` integration.

## Roadmap

### Phase 1: Core Engine (MVP) - *Current*
- [x] Initial `NSTextView` wrapper in SwiftUI.
- [x] Modal state management and basic motions.
- [x] Real-time buffer synchronization.

### Phase 2: Workspace & Preview
- [x] Workspace folder management and sidebar navigation.
- [ ] Live Markdown preview rendering.
- [ ] `.vimrc` / `.oghamrc` configuration support.

### Phase 3: Polish & Advanced Features
- [ ] Global workspace search.
- [ ] Advanced Vim motions and operators.
- [ ] Custom themes and distraction-free mode.

## Development

### Prerequisites
- macOS 14.0+ (Sonoma)
- Xcode 15+ or Swift 6 toolchain

### Building
```bash
swift build
```

### Running
```bash
swift run OghamNote
```

---

*Ogham Note: The speed of Vim, the elegance of macOS.*
