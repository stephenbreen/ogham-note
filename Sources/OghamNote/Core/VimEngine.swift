import Foundation
import AppKit

enum VimMode: String {
    case normal = "NORMAL"
    case insert = "INSERT"
    case visual = "VISUAL"
    case visualLine = "VISUAL_LINE"
    case command = "COMMAND"
}

@MainActor
class VimEngine: ObservableObject {
    @Published var mode: VimMode = .normal
    @Published var commandText: String = ""
    @Published var showHelp: Bool = false
    
    // Callback to update the actual text view
    var onTextChange: ((String) -> Void)?
    var onSelectionChange: ((NSRange) -> Void)?
    var onUndo: (() -> Void)?
    
    private var internalBuffer: String = ""
    private var cursorIndex: Int = 0
    private var desiredColumn: Int = 0 // For j/k column memory
    private var visualStartIndex: Int = 0
    
    // For multi-key commands like 'gg'
    private var pendingKeys: String = ""
    
    // Performance Optimization: Cache line offsets
    private var lineOffsets: [Int] = [0]
    
    func setBuffer(_ text: String) {
        self.internalBuffer = text
        recalculateLineOffsets()
    }
    
    func handleInput(_ key: String, currentText: String, currentSelection: NSRange) {
        if self.internalBuffer != currentText {
            self.internalBuffer = currentText
            recalculateLineOffsets()
        }
        self.cursorIndex = currentSelection.location
        
        switch mode {
        case .normal:
            handleNormalMode(key)
        case .insert:
            handleInsertMode(key)
        case .command:
            handleCommandMode(key)
        case .visual, .visualLine:
            handleVisualMode(key)
        }
    }
    
    private func handleNormalMode(_ key: String) {
        // Handle pending keys (like 'g')
        if !pendingKeys.isEmpty {
            let fullCommand = pendingKeys + key
            if fullCommand == "gg" {
                cursorIndex = 0
                updateDesiredColumnFromCurrentIndex()
                onSelectionChange?(NSRange(location: 0, length: 0))
            }
            pendingKeys = ""
            return
        }

        switch key {
        case "i":
            mode = .insert
        case "a":
            mode = .insert
            moveCursor(by: 1, updateDesiredColumn: true)
        case "A":
            mode = .insert
            moveLineEnd()
        case "o":
            insertNewLine(below: true)
            mode = .insert
        case "O":
            insertNewLine(below: false)
            mode = .insert
        case "v":
            mode = .visual
            visualStartIndex = cursorIndex
            updateSelection()
        case "V":
            mode = .visualLine
            visualStartIndex = cursorIndex
            updateSelection()
        case ":":
            mode = .command
            commandText = ":"
        case "h":
            moveCursor(by: -1, updateDesiredColumn: true)
        case "l":
            moveCursor(by: 1, updateDesiredColumn: true)
        case "j":
            moveCursorVertical(by: 1)
        case "k":
            moveCursorVertical(by: -1)
        case "w":
            moveWord(forward: true)
        case "b":
            moveWord(forward: false)
        case "0":
            moveLineStart()
        case "$":
            moveLineEnd()
        case "G":
            moveToFileEnd()
        case "g":
            pendingKeys = "g"
        case "x":
            deleteCurrentChar()
        case "u":
            onUndo?()
        case "p":
            paste()
        case "?":
            showHelp = true
        default:
            break
        }
    }
    
    private func handleInsertMode(_ key: String) {
        if key == "<Esc>" {
            mode = .normal
            updateDesiredColumnFromCurrentIndex()
            return
        }
    }
    
    private func handleCommandMode(_ key: String) {
        if key == "<Esc>" {
            mode = .normal
            commandText = ""
            return
        }
        
        if key == "<CR>" {
            executeCommand()
            mode = .normal
            commandText = ""
            return
        }
        
        if key == "<BS>" {
            if commandText.count > 1 {
                commandText.removeLast()
            } else {
                mode = .normal
                commandText = ""
            }
            return
        }
        
        if key.count == 1 {
            commandText.append(key)
        }
    }
    
    private func handleVisualMode(_ key: String) {
        switch key {
        case "<Esc>":
            mode = .normal
            onSelectionChange?(NSRange(location: cursorIndex, length: 0))
        case "h":
            moveCursor(by: -1, updateDesiredColumn: true)
        case "l":
            moveCursor(by: 1, updateDesiredColumn: true)
        case "j":
            moveCursorVertical(by: 1)
        case "k":
            moveCursorVertical(by: -1)
        case "w":
            moveWord(forward: true)
        case "b":
            moveWord(forward: false)
        case "0":
            moveLineStart()
        case "$":
            moveLineEnd()
        case "d", "x":
            deleteSelection()
            mode = .normal
        case "y":
            yankSelection()
            mode = .normal
            onSelectionChange?(NSRange(location: cursorIndex, length: 0))
        case "V":
            mode = (mode == .visualLine) ? .normal : .visualLine
            updateSelection()
        case "v":
            mode = (mode == .visual) ? .normal : .visual
            updateSelection()
        default:
            break
        }
    }
    
    // MARK: - Motions
    
    private func moveCursor(by offset: Int, updateDesiredColumn: Bool) {
        let newIndex = max(0, min(internalBuffer.count, cursorIndex + offset))
        cursorIndex = newIndex
        if updateDesiredColumn {
            updateDesiredColumnFromCurrentIndex()
        }
        updateSelection()
    }
    
    private func moveCursorVertical(by lineOffset: Int) {
        let (currentLine, _) = getLineAndColumn(for: cursorIndex)
        let targetLine = max(0, min(lineOffsets.count - 1, currentLine + lineOffset))
        
        let lineStart = lineOffsets[targetLine]
        let lineEnd = (targetLine + 1 < lineOffsets.count) ? lineOffsets[targetLine + 1] - 1 : internalBuffer.count
        let lineLength = lineEnd - lineStart
        
        let newCol = min(desiredColumn, lineLength)
        cursorIndex = lineStart + newCol
        updateSelection()
    }
    
    private func moveWord(forward: Bool) {
        let chars = Array(internalBuffer)
        var i = cursorIndex
        
        if forward {
            while i < chars.count && !chars[i].isWhitespace { i += 1 }
            while i < chars.count && chars[i].isWhitespace { i += 1 }
        } else {
            if i > 0 { i -= 1 }
            while i > 0 && chars[i].isWhitespace { i -= 1 }
            while i > 0 && !chars[i-1].isWhitespace { i -= 1 }
        }
        
        cursorIndex = i
        updateDesiredColumnFromCurrentIndex()
        updateSelection()
    }
    
    private func moveLineStart() {
        let (lineIndex, _) = getLineAndColumn(for: cursorIndex)
        cursorIndex = lineOffsets[lineIndex]
        updateDesiredColumnFromCurrentIndex()
        updateSelection()
    }
    
    private func moveLineEnd() {
        let (lineIndex, _) = getLineAndColumn(for: cursorIndex)
        let lineEnd = (lineIndex + 1 < lineOffsets.count) ? lineOffsets[lineIndex + 1] - 1 : internalBuffer.count
        cursorIndex = lineEnd
        updateDesiredColumnFromCurrentIndex()
        updateSelection()
    }

    private func moveToFileEnd() {
        cursorIndex = internalBuffer.count
        updateDesiredColumnFromCurrentIndex()
        onSelectionChange?(NSRange(location: cursorIndex, length: 0))
    }
    
    // MARK: - Actions
    
    private func insertNewLine(below: Bool) {
        let (lineIndex, _) = getLineAndColumn(for: cursorIndex)
        let insertIndex: Int
        
        if below {
            insertIndex = (lineIndex + 1 < lineOffsets.count) ? lineOffsets[lineIndex + 1] : internalBuffer.count
        } else {
            insertIndex = lineOffsets[lineIndex]
        }
        
        var chars = Array(internalBuffer)
        chars.insert("\n", at: insertIndex)
        internalBuffer = String(chars)
        cursorIndex = insertIndex
        recalculateLineOffsets()
        onTextChange?(internalBuffer)
        onSelectionChange?(NSRange(location: cursorIndex, length: 0))
    }

    private func paste() {
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.pasteboardItems,
              let text = items.first?.string(forType: .string) else { return }
        
        var chars = Array(internalBuffer)
        // Paste after current character like Vim
        let insertIndex = min(internalBuffer.count, cursorIndex + 1)
        chars.insert(contentsOf: text, at: insertIndex)
        internalBuffer = String(chars)
        cursorIndex = insertIndex + text.count - 1
        recalculateLineOffsets()
        onTextChange?(internalBuffer)
        onSelectionChange?(NSRange(location: cursorIndex, length: 0))
    }
    
    private func updateSelection() {
        if mode == .visual {
            let start = min(visualStartIndex, cursorIndex)
            let end = max(visualStartIndex, cursorIndex)
            let length = min(internalBuffer.count - start, (end - start) + 1)
            onSelectionChange?(NSRange(location: start, length: length))
        } else if mode == .visualLine {
            let startLineIdx = getLineAndColumn(for: visualStartIndex).line
            let endLineIdx = getLineAndColumn(for: cursorIndex).line
            
            let firstLine = min(startLineIdx, endLineIdx)
            let lastLine = max(startLineIdx, endLineIdx)
            
            let start = lineOffsets[firstLine]
            let endOfLastLine = (lastLine + 1 < lineOffsets.count) ? lineOffsets[lastLine + 1] : internalBuffer.count
            
            onSelectionChange?(NSRange(location: start, length: endOfLastLine - start))
        } else {
            onSelectionChange?(NSRange(location: cursorIndex, length: 0))
        }
    }
    
    private func deleteCurrentChar() {
        guard cursorIndex < internalBuffer.count else { return }
        var chars = Array(internalBuffer)
        chars.remove(at: cursorIndex)
        internalBuffer = String(chars)
        recalculateLineOffsets()
        onTextChange?(internalBuffer)
    }
    
    private func deleteSelection() {
        let startRange: NSRange
        if mode == .visual {
            let start = min(visualStartIndex, cursorIndex)
            let end = max(visualStartIndex, cursorIndex)
            let length = min(internalBuffer.count - start, (end - start) + 1)
            startRange = NSRange(location: start, length: length)
        } else if mode == .visualLine {
            let startLineIdx = getLineAndColumn(for: visualStartIndex).line
            let endLineIdx = getLineAndColumn(for: cursorIndex).line
            let firstLine = min(startLineIdx, endLineIdx)
            let lastLine = max(startLineIdx, endLineIdx)
            let start = lineOffsets[firstLine]
            let endOfLastLine = (lastLine + 1 < lineOffsets.count) ? lineOffsets[lastLine + 1] : internalBuffer.count
            startRange = NSRange(location: start, length: endOfLastLine - start)
        } else {
            return
        }
        
        var chars = Array(internalBuffer)
        chars.removeSubrange(startRange.location..<(startRange.location + startRange.length))
        internalBuffer = String(chars)
        cursorIndex = startRange.location
        recalculateLineOffsets()
        onTextChange?(internalBuffer)
        onSelectionChange?(NSRange(location: cursorIndex, length: 0))
    }
    
    private func yankSelection() {
        let startRange: NSRange
        if mode == .visual {
            let start = min(visualStartIndex, cursorIndex)
            let end = max(visualStartIndex, cursorIndex)
            let length = min(internalBuffer.count - start, (end - start) + 1)
            startRange = NSRange(location: start, length: length)
        } else if mode == .visualLine {
            let startLineIdx = getLineAndColumn(for: visualStartIndex).line
            let endLineIdx = getLineAndColumn(for: cursorIndex).line
            let firstLine = min(startLineIdx, endLineIdx)
            let lastLine = max(startLineIdx, endLineIdx)
            let start = lineOffsets[firstLine]
            let endOfLastLine = (lastLine + 1 < lineOffsets.count) ? lineOffsets[lastLine + 1] : internalBuffer.count
            startRange = NSRange(location: start, length: endOfLastLine - start)
        } else {
            return
        }
        
        let startIdx = internalBuffer.index(internalBuffer.startIndex, offsetBy: startRange.location)
        let endIdx = internalBuffer.index(internalBuffer.startIndex, offsetBy: startRange.location + startRange.length)
        let yankedText = String(internalBuffer[startIdx..<endIdx])
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(yankedText, forType: .string)
    }
    
    private func executeCommand() {
        let cmd = commandText.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
        if cmd == "w" {
            print("Save requested")
        } else if cmd == "q" {
            NSApp.terminate(nil)
        }
    }
    
    // MARK: - Helpers (Optimized)
    
    private func recalculateLineOffsets() {
        var offsets = [0]
        var current = 0
        for char in internalBuffer {
            current += 1
            if char == "\n" {
                offsets.append(current)
            }
        }
        self.lineOffsets = offsets
    }
    
    private func updateDesiredColumnFromCurrentIndex() {
        let (_, col) = getLineAndColumn(for: cursorIndex)
        desiredColumn = col
    }
    
    private func getLineAndColumn(for index: Int) -> (line: Int, col: Int) {
        // Binary search for the line index
        var low = 0
        var high = lineOffsets.count - 1
        var lineIndex = 0
        
        while low <= high {
            let mid = (low + high) / 2
            if lineOffsets[mid] <= index {
                lineIndex = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        let colIndex = index - lineOffsets[lineIndex]
        return (lineIndex, colIndex)
    }
}
