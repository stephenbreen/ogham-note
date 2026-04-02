import SwiftUI

struct HelpView: View {
    let theme: AppTheme
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ogham Note Cheat Sheet")
                    .font(.headline)
                    .foregroundColor(theme.accent)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(theme.secondaryBackground)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        ModeSection(title: "NORMAL MODE", color: theme.normalMode, shortcuts: [
                            ("i", "Enter Insert Mode"),
                            ("v", "Enter Visual Mode"),
                            (":", "Enter Command Mode"),
                            ("h, j, k, l", "Move Left, Down, Up, Right"),
                            ("w, b", "Next/Previous Word"),
                            ("0, $", "Line Start / End"),
                            ("x", "Delete Character"),
                            ("?", "Show this Help")
                        ])
                        
                        ModeSection(title: "INSERT MODE", color: theme.insertMode, shortcuts: [
                            ("<Esc>", "Return to Normal Mode"),
                            ("Typing", "Standard text entry")
                        ])
                        
                        ModeSection(title: "VISUAL MODE", color: theme.visualMode, shortcuts: [
                            ("<Esc>", "Return to Normal Mode"),
                            ("h, j, k, l", "Expand Selection"),
                            ("d, x", "Delete Selection"),
                            ("y", "Yank (Copy) Selection")
                        ])
                        
                        ModeSection(title: "COMMAND MODE", color: theme.commandMode, shortcuts: [
                            (":w", "Save (Placeholder)"),
                            (":q", "Quit Application"),
                            ("<Esc>", "Cancel Command"),
                            ("<CR>", "Execute Command")
                        ])
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
        .background(theme.background)
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

struct ModeSection: View {
    let title: String
    let color: Color
    let shortcuts: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(4)
            
            ForEach(shortcuts, id: \.0) { key, desc in
                HStack {
                    Text(key)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .leading)
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
