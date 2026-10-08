import Foundation
import MASShortcut

class ShortcutManager {
    let windowManager: WindowManager
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        registerDefaults()
        bindShortcuts()
    }
    
    public func bindShortcuts() {
        for action in WindowAction.active {
            MASShortcutBinder.shared()?.bindShortcut(withDefaultsKey: action.name) { [weak self] in
                self?.windowManager.execute(action)
            }
        }
    }
    
    public func unbindShortcuts() {
        for action in WindowAction.active {
            MASShortcutBinder.shared()?.breakBinding(withDefaultsKey: action.name)
        }
    }
    
    public func getKeyEquivalent(action: WindowAction) -> (String?, NSEvent.ModifierFlags)? {
        guard let masShortcut = MASShortcutBinder.shared()?.value(forKey: action.name) as? MASShortcut else { return nil }
        return (masShortcut.keyCodeStringForKeyEquivalent, masShortcut.modifierFlags)
    }
    
    private func registerDefaults() {
        let defaultShortcuts = WindowAction.active.reduce(into: [String: MASShortcut]()) { dict, windowAction in
            let shortcut = MASShortcut(keyCode: windowAction.keybindingDefaults.keyCode,
                                       modifierFlags: NSEvent.ModifierFlags(rawValue: windowAction.keybindingDefaults.modifierFlags))
            dict[windowAction.name] = shortcut
        }
        
        MASShortcutBinder.shared()?.registerDefaultShortcuts(defaultShortcuts)
    }
}
