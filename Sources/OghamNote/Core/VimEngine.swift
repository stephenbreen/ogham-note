import Foundation
import AppKit

enum VimMode: String {
    case normal = "NORMAL"
    case insert = "INSERT"
    case visual = "VISUAL"
    case visualLine = "VISUAL_LINE"
    case command = "COMMAND"
    case search = "SEARCH"
}

enum VimOperator: String {
    case delete = "d"
    case yank = "y"
    case change = "c"
    case indent = ">"
    case outdent = "<"
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
    var onInsertModeStarted: (() -> Void)?
    var onInsertModeEnded: (() -> Void)?
    
    private var internalBuffer: String = ""
    private var cursorIndex: Int = 0
    private var desiredColumn: Int = 0 // For j/k column memory
    private var visualStartIndex: Int = 0
    
    // For multi-key commands like 'gg' or 'dw'
    private var pendingKeys: String = ""
    private var pendingOperator: VimOperator?
    
    // For search
    @Published var lastSearchQuery: String = ""
    private var isSearchForward: Bool = true
    
    // Performance Optimization: Cache line offsets
    private var lineOffsets: [Int] = [0]

    // For repeat command '.'
    private struct VimAction {
        let op: VimOperator
        let range: NSRange?
        let command: String?
    }
    private var lastAction: VimAction?
    
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
        case .search:
            handleSearchMode(key)
        case .visual, .visualLine:
            handleVisualMode(key)
        }
    }
    
    private func handleNormalMode(_ key: String) {
        // Handle pending operator (e.g., 'd' was pressed, waiting for motion)
        if let op = pendingOperator {
            handleOperatorMotion(op, key: key)
            return
        }

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
            onInsertModeStarted?()
        case "a":
            mode = .insert
            onInsertModeStarted?()
            moveCursor(by: 1, updateDesiredColumn: true)
        case "A":
            mode = .insert
            onInsertModeStarted?()
            moveLineEnd()
        case "o":
            onInsertModeStarted?()
            insertNewLine(below: true)
            mode = .insert
        case "O":
            onInsertModeStarted?()
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
        case "/":
            mode = .search
            isSearchForward = true
            commandText = "/"
        case "?":
            mode = .search
            isSearchForward = false
            commandText = "?"
        case "n":
            findNextMatch(forward: isSearchForward)
        case "N":
            findNextMatch(forward: !isSearchForward)
        case "d":
            pendingOperator = .delete
        case "y":
            pendingOperator = .yank
        case "c":
            pendingOperator = .change
        case "x":
            deleteCurrentChar()
        case "u":
            onUndo?()
        case "p":
            paste()
        case ".":
            repeatLastAction()
        case "?":
            showHelp = true
        default:
            break
        }
    }

    private func repeatLastAction() {
        guard let last = lastAction else { return }
        
        if let cmd = last.command {
            if let newRange = resolveMotionRange(for: cmd) {
                executeOperator(last.op, range: newRange, saveForRepeat: false)
            } else if let newRange = resolveTextObjectRange(for: cmd) {
                executeOperator(last.op, range: newRange, saveForRepeat: false)
            } else if cmd == last.op.rawValue { // Double key like 'dd'
                let (lineIdx, _) = getLineAndColumn(for: cursorIndex)
                let start = lineOffsets[lineIdx]
                let end = (lineIdx + 1 < lineOffsets.count) ? lineOffsets[lineIdx + 1] : internalBuffer.count
                executeOperator(last.op, range: NSRange(location: start, length: end - start), saveForRepeat: false)
            }
        }
    }

    private func handleOperatorMotion(_ op: VimOperator, key: String) {
        // Handle double-key operators (dd, yy, cc)
        if key == op.rawValue {
            let (lineIdx, _) = getLineAndColumn(for: cursorIndex)
            let start = lineOffsets[lineIdx]
            let end = (lineIdx + 1 < lineOffsets.count) ? lineOffsets[lineIdx + 1] : internalBuffer.count
            executeOperator(op, range: NSRange(location: start, length: end - start), saveForRepeat: true, command: key)
            pendingOperator = nil
            return
        }

        let fullCommand = pendingKeys + key
        
        // Handle text objects (e.g., iw, aw, i", etc.)
        if let range = resolveTextObjectRange(for: fullCommand) {
            executeOperator(op, range: range, saveForRepeat: true, command: fullCommand)
            pendingOperator = nil
            pendingKeys = ""
            return
        }

        // Handle motions after operator (e.g., dw, y$, dgg)
        if let range = resolveMotionRange(for: fullCommand) {
            executeOperator(op, range: range, saveForRepeat: true, command: fullCommand)
            pendingOperator = nil
            pendingKeys = ""
        } else if key == "<Esc>" {
            pendingOperator = nil
            pendingKeys = ""
        } else {
            // Part of a multi-key motion or text object
            pendingKeys += key
            // Limit pending keys to prevent infinite accumulation
            if pendingKeys.count > 3 {
                pendingOperator = nil
                pendingKeys = ""
            }
        }
    }

    private func resolveTextObjectRange(for command: String) -> NSRange? {
        guard command.count >= 2 else { return nil }
        let type = command.prefix(1) // 'i' or 'a'
        let object = command.suffix(1) // 'w', '"', '(', etc.
        
        switch (type, object) {
        case ("i", "w"):
            return getInnerWordRange(at: cursorIndex)
        case ("a", "w"):
            return getAWordRange(at: cursorIndex)
        default:
            return nil
        }
    }

    private func getInnerWordRange(at index: Int) -> NSRange {
        let chars = Array(internalBuffer)
        if index >= chars.count { return NSRange(location: index, length: 0) }
        
        var start = index
        var end = index
        
        // Find start of word
        while start > 0 && !chars[start-1].isWhitespace { start -= 1 }
        // Find end of word
        while end < chars.count && !chars[end].isWhitespace { end += 1 }
        
        return NSRange(location: start, length: end - start)
    }

    private func getAWordRange(at index: Int) -> NSRange {
        let inner = getInnerWordRange(at: index)
        let chars = Array(internalBuffer)
        var end = inner.location + inner.length
        
        // Include following whitespace
        while end < chars.count && chars[end].isWhitespace { end += 1 }
        
        return NSRange(location: inner.location, length: end - inner.location)
    }

    private func resolveMotionRange(for key: String) -> NSRange? {
        let start = cursorIndex
        var end = cursorIndex

        switch key {
        case "w":
            end = getWordEnd(from: start, forward: true)
        case "b":
            end = getWordEnd(from: start, forward: false)
        case "$":
            let (lineIdx, _) = getLineAndColumn(for: cursorIndex)
            end = (lineIdx + 1 < lineOffsets.count) ? lineOffsets[lineIdx + 1] - 1 : internalBuffer.count
        case "0":
            let (lineIdx, _) = getLineAndColumn(for: cursorIndex)
            end = lineOffsets[lineIdx]
        case "G":
            end = internalBuffer.count
        case "gg":
            end = 0
        case "j":
            let (lineIdx, _) = getLineAndColumn(for: cursorIndex)
            if lineIdx + 1 < lineOffsets.count {
                let nextLineEnd = (lineIdx + 2 < lineOffsets.count) ? lineOffsets[lineIdx + 2] : internalBuffer.count
                return NSRange(location: lineOffsets[lineIdx], length: nextLineEnd - lineOffsets[lineIdx])
            }
        case "k":
            let (lineIdx, _) = getLineAndColumn(for: cursorIndex)
            if lineIdx > 0 {
                let prevLineStart = lineOffsets[lineIdx - 1]
                let currentLineEnd = (lineIdx + 1 < lineOffsets.count) ? lineOffsets[lineIdx + 1] : internalBuffer.count
                return NSRange(location: prevLineStart, length: currentLineEnd - prevLineStart)
            }
        default:
            return nil
        }

        let minIdx = min(start, end)
        let maxIdx = max(start, end)
        return NSRange(location: minIdx, length: maxIdx - minIdx)
    }

    private func executeOperator(_ op: VimOperator, range: NSRange, saveForRepeat: Bool = true, command: String? = nil) {
        if saveForRepeat {
            lastAction = VimAction(op: op, range: range, command: command)
        }
        
        switch op {
        case .delete:
            deleteRange(range)
        case .yank:
            yankRange(range)
        case .change:
            deleteRange(range)
            mode = .insert
        case .indent, .outdent:
            // TODO: Implement indentation logic
            break
        }
    }

    private func deleteRange(_ range: NSRange) {
        var chars = Array(internalBuffer)
        let safeLength = min(range.length, internalBuffer.count - range.location)
        if safeLength <= 0 { return }
        
        // Save to register before deleting
        yankRange(NSRange(location: range.location, length: safeLength))
        
        chars.removeSubrange(range.location..<(range.location + safeLength))
        internalBuffer = String(chars)
        cursorIndex = range.location
        recalculateLineOffsets()
        onTextChange?(internalBuffer)
        onSelectionChange?(NSRange(location: cursorIndex, length: 0))
    }

    private func yankRange(_ range: NSRange) {
        let safeLength = min(range.length, internalBuffer.count - range.location)
        if safeLength <= 0 { return }
        
        let startIdx = internalBuffer.index(internalBuffer.startIndex, offsetBy: range.location)
        let endIdx = internalBuffer.index(internalBuffer.startIndex, offsetBy: range.location + safeLength)
        let yankedText = String(internalBuffer[startIdx..<endIdx])
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(yankedText, forType: .string)
    }

    private func getWordEnd(from index: Int, forward: Bool) -> Int {
        let chars = Array(internalBuffer)
        var i = index
        
        if forward {
            while i < chars.count && !chars[i].isWhitespace { i += 1 }
            // For 'dw', it often includes the following whitespace
            while i < chars.count && chars[i].isWhitespace { i += 1 }
        } else {
            if i > 0 { i -= 1 }
            while i > 0 && chars[i].isWhitespace { i -= 1 }
            while i > 0 && !chars[i-1].isWhitespace { i -= 1 }
        }
        return i
    }
    
    private func handleInsertMode(_ key: String) {
        if key == "<Esc>" {
            mode = .normal
            onInsertModeEnded?()
            updateDesiredColumnFromCurrentIndex()
            return
        }
    }
    
    private func handleSearchMode(_ key: String) {
        if key == "<Esc>" {
            mode = .normal
            commandText = ""
            return
        }
        
        if key == "<CR>" {
            let query = commandText.dropFirst()
            if !query.isEmpty {
                lastSearchQuery = String(query)
                findNextMatch(forward: isSearchForward)
            }
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

    private func findNextMatch(forward: Bool) {
        guard !lastSearchQuery.isEmpty else { return }
        
        let nsString = internalBuffer as NSString
        var searchRange: NSRange
        
        if forward {
            let startPos = min(internalBuffer.count, cursorIndex + 1)
            searchRange = NSRange(location: startPos, length: internalBuffer.count - startPos)
            var result = nsString.range(of: lastSearchQuery, options: .caseInsensitive, range: searchRange)
            
            if result.location == NSNotFound {
                // Wrap around to the beginning
                searchRange = NSRange(location: 0, length: cursorIndex)
                result = nsString.range(of: lastSearchQuery, options: .caseInsensitive, range: searchRange)
            }
            
            if result.location != NSNotFound {
                cursorIndex = result.location
                onSelectionChange?(NSRange(location: cursorIndex, length: 0))
            }
        } else {
            let endPos = max(0, cursorIndex)
            searchRange = NSRange(location: 0, length: endPos)
            var result = nsString.range(of: lastSearchQuery, options: [.caseInsensitive, .backwards], range: searchRange)
            
            if result.location == NSNotFound {
                // Wrap around to the end
                let startPos = min(internalBuffer.count, cursorIndex)
                searchRange = NSRange(location: startPos, length: internalBuffer.count - startPos)
                result = nsString.range(of: lastSearchQuery, options: [.caseInsensitive, .backwards], range: searchRange)
            }
            
            if result.location != NSNotFound {
                cursorIndex = result.location
                onSelectionChange?(NSRange(location: cursorIndex, length: 0))
            }
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
        
        // Incremental Update: Add a new offset and shift subsequent ones
        let newLineIndex = below ? lineIndex + 1 : lineIndex
        lineOffsets.insert(insertIndex + 1, at: newLineIndex + 1)
        for i in (newLineIndex + 2)..<lineOffsets.count {
            lineOffsets[i] += 1
        }
        
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
        let charToDelete = internalBuffer[internalBuffer.index(internalBuffer.startIndex, offsetBy: cursorIndex)]
        
        var chars = Array(internalBuffer)
        chars.remove(at: cursorIndex)
        internalBuffer = String(chars)
        
        if charToDelete == "\n" {
            // If we deleted a newline, remove that offset
            let (lineIndex, _) = getLineAndColumn(for: cursorIndex)
            if lineIndex + 1 < lineOffsets.count {
                lineOffsets.remove(at: lineIndex + 1)
            }
        }
        
        // Shift subsequent offsets
        let (affectedLine, _) = getLineAndColumn(for: cursorIndex)
        for i in (affectedLine + 1)..<lineOffsets.count {
            lineOffsets[i] -= 1
        }
        
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
