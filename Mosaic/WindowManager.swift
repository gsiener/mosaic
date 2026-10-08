import Cocoa

let DEBUG = false

class WindowManager {
    private var windowHistory: [WindowId: WindowEvent]
    
    init() {
        self.windowHistory = [WindowId: WindowEvent]()
    }
    
    func execute(_ action: WindowAction) {
        guard let screens = Screens.detect(),
            let window = Window.frontmostWindow(screens: screens) else {
            NSSound.beep()
            return
        }
        
        guard window.isAdjustable,
            let id = window.getIdentifier(),
            let screen = screens.screenContaining(window) else {
            return
        }
        
        let current = window.normalizedRect(in: screen)
        let target = Layout.target(for: action, current: current, previous: self.windowHistory[id])
        let targetScreen = action == .switchDisplay ? screens.screenAfter(screen) : screen
        window.adjust(to: target, on: targetScreen)
        self.windowHistory[id] = WindowEvent(id: id, previous: current, target: target)
        
        if DEBUG {
            print("Screens")
            print("=======")
            for s in screens.screens {
                if screen == s {
                    print("\t**Frame: \(s.frame), Visible Frame: \(s.visibleFrame))**")
                } else {
                    print("\tFrame: \(s.frame), Visible Frame: \(s.visibleFrame))")
                }
            }
            print("Window")
            print("\t", id)
            print("\tRect:", window.rect())
            print("\tNormalized Rect:", window.normalizedRect(in: screen))
            print("\tTarget:", target)
        }
    }
}
