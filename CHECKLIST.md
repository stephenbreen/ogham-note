# Checklist: Ogham Note Development

## Phase 1: Core Engine (MVP)
- [x] Initial Project Setup (SPM, Directory Structure)
- [x] SwiftUI App Shell with Glassmorphism background
- [x] `NSTextView` wrapper in SwiftUI
- [x] Integration of `libvim.swift` and `VimCore` class
- [ ] Override `keyDown` in `NSTextView` to route to `libvim`
- [ ] Sync `libvim` buffer with `NSTextView` in real-time
- [ ] Implement Visual/Command mode indicators/UI
- [ ] Basic Markdown Syntax Highlighting in `NSTextView`

## Phase 2: Workspace & Preview
- [ ] File System Observer for Sidebar
- [ ] Navigation and File Opening logic
- [ ] Integration of `swift-markdown` for Preview rendering
- [ ] Side-by-side Toggle View
- [ ] `.vimrc` loading and parsing

## Phase 3: Polish & Advanced Features
- [ ] Global Search (Grep implementation)
- [ ] Customizeable Typography & Theming
- [ ] Command line (bottom bar) for `:` commands
- [ ] Performance benchmarks and optimization
- [ ] App Icon and polished metadata
