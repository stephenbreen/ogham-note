# PRD: Ogham Note - Minimalist Vim Markdown Editor for macOS

## 1. Executive Summary
**Ogham Note** is a high-performance, native macOS Markdown editor designed for users who demand the speed of Vim and the elegance of a minimalist desktop application. It avoids the overhead of Electron-based editors by using a native Swift/SwiftUI frontend and a C-based Vim engine (`libvim`).

## 2. Goals & Objectives
- Provide a **near-zero latency** typing experience.
- Implement **authentic Vim editing** (not just a subset of keybindings).
- Offer a **distraction-free**, ultra-minimalist interface.
- Support **workspace-based** file management similar to Obsidian.

## 3. Target Audience
- Developers, technical writers, and power users who are already proficient in Vim.
- Users who find existing Markdown editors (Obsidian, VS Code) too heavy or non-native.

## 4. Technical Stack
- **Language:** Swift 6.
- **UI Framework:** SwiftUI (for the app shell) and AppKit/`NSTextView` (for the high-performance text core).
- **Vim Engine:** `libvim` (C-based Vim core) integrated via `libvim.swift`.
- **Markdown Engine:** `swift-markdown` (Apple's Markdown parser) for performant rendering.
- **Platform:** macOS 14.0+ (Sonoma).

## 5. Functional Requirements

### 5.1. Vim Integration
- **Full Modal Support:** Normal, Insert, Visual, Visual Line, and Command-line modes.
- **Keybindings:** Support for standard Vim motions, operators, and text objects.
- **Configuration:** Ability to load a `.vimrc` file from a custom location or `~/.oghamrc`.
- **Command Line:** A minimalist command-bar at the bottom of the window for `:` commands.

### 5.2. Workspace Management
- **Sidebar:** A toggleable file explorer showing the current workspace/folder structure.
- **File Operations:** Basic create, delete, and rename functionality within the sidebar.
- **Search:** Global search (grep-like) across the workspace files.

### 5.3. Markdown Features
- **Live Toggle Preview:** A side-by-side or full-window preview mode that renders Markdown.
- **Syntax Highlighting:** Native code highlighting for Markdown syntax and fenced code blocks.
- **Math Support:** LaTeX rendering via MathJax or KaTeX in the preview.

### 5.4. Aesthetics & UI
- **Ultra-Minimalist:** No toolbars, no status bars (unless in command mode), no window borders.
- **Vibrancy:** Use of macOS "Glassmorphism" (System Material) for the sidebar and editor background.
- **Typography:** Defaulting to SF Mono with customizable line height and font size.

## 6. Non-Functional Requirements
- **Performance:** App launch in <1 second; zero lag on files >10k lines.
- **Portability:** Configurations and notes should be stored in plain text/standard Markdown.
- **Security:** Sandbox-compliant (unless configured for full disk access for specific workspaces).

## 7. Roadmap & Phases

### Phase 1: Core Engine (MVP)
- Integration of `libvim.swift`.
- Basic `NSTextView` wrapper with Vim mode switching.
- Minimalist window with single file support.

### Phase 2: Workspace & Preview
- Sidebar implementation for folder browsing.
- `swift-markdown` integration for toggleable preview.
- `.vimrc` loading support.

### Phase 3: Polish & Advanced Features
- Global search.
- Theme support (Nord, Dracula, Gruvbox).
- Custom plugins/VimL support via `libvim`.
