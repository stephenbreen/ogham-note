# Detailed Checklist: Ogham Note

## Phase 1: Core Engine (Pure Swift Vim-Lite)
- [x] Initial `NSTextView` wrapper in SwiftUI.
- [x] **Vim Engine (Pure Swift):**
    - [x] Modal state management (Normal, Insert, Visual, Command).
    - [x] Keyboard routing via `VimKeyMapper`.
    - [x] Basic motions (`h`, `l`).
    - [ ] Robust vertical motions (`j`, `k`) with column memory.
    - [ ] Word motions (`w`, `b`, `e`).
    - [ ] Line start/end (`0`, `$`).
- [x] **Buffer Synchronization:**
    - [x] Real-time text and selection sync between `VimEngine` and `NSTextView`.
- [x] **UI Infrastructure:**
    - [x] Reactive `StatusBarView`.
    - [x] Command-line display in status bar.

---

## Phase 2: Workspace & Preview

### 2.1 Workspace Management
- [x] **File System:**
    - [x] Recursive `FileItem` model.
    - [x] Workspace folder selection.
- [x] **Sidebar UI:**
    - [x] `OutlineGroup` sidebar with file navigation.
    - [x] File opening and content loading.

### 2.2 Markdown Preview
- [ ] **Rendering Engine:**
    - [ ] Integrate `swift-markdown` to parse content.
    - [ ] Implement a basic SwiftUI renderer for common Markdown elements (Headers, Lists, Code).
- [ ] **Synchronization:**
    - [x] Content passing from Editor -> Preview.
    - [ ] Debounced rendering for performance.

### 2.2 Markdown Preview
- [ ] **Rendering Engine:**
    - [ ] Integrate `swift-markdown` to generate an AST.
    - [ ] Create a SwiftUI-based renderer for the AST (or a lightweight HTML bridge).
- [ ] **Synchronization:**
    - [ ] Implement debounced updates from Editor -> Preview.
    - [ ] Add "Sync Scroll" (optional but recommended).

### 2.3 Configuration (.vimrc)
- [ ] Implement a loader for `~/.oghamrc` or `~/.vimrc`.
- [ ] Map standard Vim settings (e.g., `set tabstop=4`) to `libvim` initialization.

---

## Phase 3: Polish & Advanced Features

### 3.1 Global Search
- [ ] Implement a "Search Workspace" UI.
- [ ] Build a performant search runner (using `grep` or native Swift).
- [ ] Add navigation from search results to file/line.

### 3.2 Aesthetics & Themes
- [ ] Define a `Theme` system (JSON or Swift-based).
- [ ] Implement "Distraction Free" mode (hiding sidebar and status bar).
- [ ] Polish window animations and transitions.

### 3.3 Performance & Stability
- [ ] Profile memory usage with large buffers.
- [ ] Stress test `libvim` synchronization with macros.
- [ ] Finalize App Icon and macOS metadata.
