import SwiftUI

struct CommandBarView: View {
    @ObservedObject var vimEngine: VimEngine
    let theme: AppTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Mode Indicator
            Text(vimEngine.mode.rawValue)
                .font(.system(size: 10, weight: .black))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(modeColor)
                .foregroundColor(.white)
                .cornerRadius(3)
                .padding(.trailing, 8)
            
            if vimEngine.mode == .command || vimEngine.mode == .search {
                // Interactive Command/Search Input
                TextField("", text: $vimEngine.commandText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(theme.foreground)
                    .focused($isFocused)
                    .onSubmit {
                        // Enter handled by VimEngine via handleInput, 
                        // but we need this to keep the TextField active or handle finalization
                    }
                    .onChange(of: vimEngine.mode) { oldMode, newMode in
                        if newMode == .command || newMode == .search {
                            isFocused = true
                        } else {
                            isFocused = false
                        }
                    }
            } else {
                // Static Info
                if !vimEngine.lastSearchQuery.isEmpty {
                    Text("/\(vimEngine.lastSearchQuery)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Placeholder for line/col info later
                Text("L: \(currentLine) C: \(currentCol)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(VisualEffectView(material: .contentBackground, blendingMode: .withinWindow))
        .onAppear {
            if vimEngine.mode == .command || vimEngine.mode == .search {
                isFocused = true
            }
        }
    }

    private var modeColor: Color {
        switch vimEngine.mode {
        case .normal: return theme.normalMode
        case .insert: return theme.insertMode
        case .visual, .visualLine: return theme.visualMode
        case .command: return theme.commandMode
        case .search: return theme.accent
        }
    }
    
    // Simple mock for now, will be updated to real values
    private var currentLine: Int { 1 }
    private var currentCol: Int { 1 }
}
