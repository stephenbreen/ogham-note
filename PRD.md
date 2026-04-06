# PRD: Ogham Note - Minimalist Vim Markdown Editor for macOS

## 1. Executive Summary
**Ogham Note** is a high-performance, native macOS Markdown editor designed for users who demand the speed of Vim and the elegance of a minimalist desktop application. It avoids the overhead of Electron-based editors by using a native Swift/SwiftUI frontend and a highly optimized, custom Swift-based Vim engine.

## 2. Goals & Objectives
- Provide a **near-zero latency** typing experience.
- Implement a **robust Swift-based Vim emulator** that supports advanced motions, operators, and text objects.
- Offer a **distraction-free**, ultra-minimalist interface.
- Support **workspace-based** file management similar to Obsidian.

## 3. Target Audience
- Developers, technical writers, and power users who are already proficient in Vim.
- Users who find existing Markdown editors (Obsidian, VS Code) too heavy or non-native.

## 4. Technical Stack
- **Language:** Swift 6.
- **UI Framework:** SwiftUI (for the app shell) and AppKit/`NSTextView` (for the high-performance text core).
- **Vim Engine:** Custom Swift-based Vim engine (`VimEngine`) built for performance and deep integration with `NSTextView`.
- **Markdown Engine:** `swift-markdown` (Apple's Markdown parser) for performant rendering.
- **Platform:** macOS 14.0+ (Sonoma).

## 5. Functional Requirements

### 5.1. Vim Engine (Custom Swift Implementation)
- **Full Modal Support:** Normal, Insert, Visual, Visual Line, and Command-line modes.
- **Advanced Motions:** Support for standard Vim motions (`h/j/k/l`, `w/e/b`, `0/$`, `gg/G`, `{/}`, `f/t/F/T`).
- **Operators & Text Objects:** Implementation of the operator-motion pattern (e.g., `d`, `c`, `y`, `>`) combined with text objects (e.g., `iw`, `aw`, `i"`, `it`, `ip`).
- **Registers:** Support for yank/delete registers (unnamed, numbered, and named).
- **Search & Replace:** Buffer-local search (`/`, `?`) with `n/N` navigation and basic `:s` command support.
- **Undo/Redo:** Deep integration with `NSUndoManager` while maintaining Vim's atomic action logic.
- **Repeatable Actions:** Support for the `.` command to repeat the last change.
- **Configuration:** Ability to load a simplified `.oghamrc` for key remapping and settings.

### 5.2. Workspace Management
- **Sidebar:** A toggleable file explorer showing the current workspace/folder structure.
- **File Operations:** Basic create, delete, and rename functionality within the sidebar.
- **Search:** Global search (grep-like) across the workspace files.
- **Exclusions:** Native support for `.gitignore` to keep the workspace clean.

### 5.3. Markdown Features
- **Live Toggle Preview:** A side-by-side or full-window preview mode that renders Markdown.
- **Syntax Highlighting:** High-performance Markdown syntax highlighting using AST-based parsing.
- **Math Support:** LaTeX rendering in the preview.

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
- Expansion of the custom `VimEngine` to support basic operators (`d`, `y`, `p`).
- Core `NSTextView` wrapper with improved mode switching and cursor synchronization.
- Basic window with single file support.

### Phase 2: Advanced Vim & Workspace
- Implementation of text objects (`iw`, `it`) and registers.
- Sidebar implementation with background directory scanning and `.gitignore` support.
- `swift-markdown` integration for toggleable preview.

### Phase 3: Search & Polish
- Global workspace search with indexing.
- Buffer-local search (`/`, `?`).
- Theme support and `.oghamrc` configuration.
