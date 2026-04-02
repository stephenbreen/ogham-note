import Foundation
import libvim

class VimCore: ObservableObject {
    @Published var currentMode: String = "NORMAL"
    
    init() {
        vimInit()
        // Basic configuration
        vimExecute("set number")
        vimExecute("set relativenumber")
    }

    func input(_ key: String) {
        vimKey(key)
        updateMode()
    }

    private func updateMode() {
        let mode = vimGetMode()
        switch mode {
        case 0: currentMode = "NORMAL"
        case 1: currentMode = "INSERT"
        case 2: currentMode = "VISUAL"
        case 3: currentMode = "VISUAL_LINE"
        case 4: currentMode = "COMMAND"
        default: currentMode = "NORMAL"
        }
    }

    deinit {
        // libvim cleanup if needed
    }
}
