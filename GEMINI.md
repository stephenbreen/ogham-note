# GEMINI.md - Ogham Note Project Mandates

This file contains foundational mandates for the development of **Ogham Note**. These instructions take absolute precedence over general workflows.

## 1. Architectural Principles
- **Native First:** Always prioritize native AppKit/SwiftUI components over web-based or cross-platform abstractions.
- **Performance:** Ensure near-zero latency for text input. All text processing must be asynchronous or highly optimized to avoid blocking the main thread.
- **Vim Integrity:** `libvim` is the source of truth for buffer state and modal logic. The `NSTextView` acts as a high-performance "view" of the `libvim` buffer.
- **Minimalism:** Every UI element must justify its existence. Avoid toolbars, menus, or status indicators unless they are functionally necessary for the current mode.

## 2. Coding Standards (Swift)
- **Swift 6:** Use modern Swift features (async/await, structured concurrency) while maintaining compatibility with macOS 14+.
- **Decoupling:** Keep the `VimCore` (C-bridge) strictly separated from the SwiftUI/AppKit UI layer.
- **Testing:** Every core logic change (keyboard mapping, buffer sync) must have a corresponding unit test.
- **Typing:** Favor strong types over raw strings (e.g., `VimMode` enum instead of a String).

## 3. Tooling & Dependencies
- **libvim.swift:** The primary interface for Vim functionality.
- **swift-markdown:** The primary interface for Markdown parsing.
- **Git:** All changes must be traceable. Use descriptive commit messages following Conventional Commits (e.g., `feat:`, `fix:`, `refactor:`).

## 4. UI/UX Constraints
- **Typography:** SF Mono (System Monospaced) is the default. Maintain proper line height (1.4 - 1.6) for readability.
- **Vibrancy:** Use `NSVisualEffectView` for the background to achieve the macOS "glassmorphism" look.
- **Modes:** Modes must be visually distinct but subtle (e.g., changing the cursor shape or a small indicator).

## 5. Security & Safety
- **Sandbox:** Maintain macOS Sandbox compatibility by default.
- **File Access:** Use Security-Scoped Bookmarks when accessing files outside the application's container (workspaces).
