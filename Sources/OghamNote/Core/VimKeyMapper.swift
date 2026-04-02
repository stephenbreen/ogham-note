import AppKit

struct VimKeyMapper {
    static func string(from event: NSEvent) -> String? {
        let modifiers = event.modifierFlags
        let isControl = modifiers.contains(.control)
        let isOption = modifiers.contains(.option)
        let isCommand = modifiers.contains(.command)
        let isShift = modifiers.contains(.shift)

        // Ignore all keys if Command is held (let system handle shortcuts like zoom)
        if isCommand {
            return nil
        }

        // Handle special keys first
        if let specialKey = mapSpecialKey(event.keyCode) {
            return applyModifiers(to: specialKey, control: isControl, option: isOption, shift: isShift)
        }

        // Handle standard characters
        guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
            return nil
        }

        let char = characters.first!

        // If it's a control character (e.g. Ctrl+A), it often comes in as a non-printable char.
        // We handle explicit control modifiers manually for clarity.
        if isControl {
            return "<C-\(char)>"
        }
        
        if isOption {
            return "<M-\(char)>"
        }

        // Return the character directly (Shift is already handled by 'characters' for most keys)
        return String(char)
    }

    internal static func mapSpecialKey(_ keyCode: UInt16) -> String? {
        switch keyCode {
        case 53: return "<Esc>"
        case 51: return "<BS>"
        case 36: return "<CR>"
        case 48: return "<Tab>"
        case 126: return "<Up>"
        case 125: return "<Down>"
        case 123: return "<Left>"
        case 124: return "<Right>"
        case 117: return "<Del>"
        case 115: return "<Home>"
        case 119: return "<End>"
        case 116: return "<PageUp>"
        case 121: return "<PageDown>"
        default: return nil
        }
    }

    private static func applyModifiers(to key: String, control: Bool, option: Bool, shift: Bool) -> String {
        var result = key
        // Note: libvim handles some of these internally if they are already in <Key> format
        // But we ensure the wrapper is explicit.
        if control && !result.contains("C-") {
            result = result.replacingOccurrences(of: "<", with: "<C-")
        }
        if option && !result.contains("M-") {
            result = result.replacingOccurrences(of: "<", with: "<M-")
        }
        // Shift is usually implicit in the character, but for special keys like <S-Tab> it matters
        if shift && !result.contains("S-") && (key == "<Tab>" || key.contains("Up") || key.contains("Down")) {
            result = result.replacingOccurrences(of: "<", with: "<S-")
        }
        return result
    }
}
