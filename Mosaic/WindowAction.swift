import Foundation
import Carbon
import Cocoa

fileprivate let alt = NSEvent.ModifierFlags.option.rawValue
fileprivate let ctrl = NSEvent.ModifierFlags.control.rawValue
fileprivate let cmd = NSEvent.ModifierFlags.command.rawValue

// The raw value is the user defaults key MASShortcut stores each shortcut under.
enum WindowAction: String, CaseIterable {
    // Order matters here - it's used in the menu
    case moveLeft,
    moveRight,
    moveUp,
    moveDown,
    maximize,
    center,
    switchDisplay

    static let active = allCases

    private struct Descriptor {
        let displayName: String
        let shortcut: Shortcut
        let imageName: String
        // Determines where separators should be used in the menu
        var firstInGroup = false
    }

    private var descriptor: Descriptor {
        switch self {
        case .moveLeft: return Descriptor(displayName: "Move Left", shortcut: Shortcut(cmd|alt|ctrl, kVK_LeftArrow), imageName: "moveLeftTemplate", firstInGroup: true)
        case .moveRight: return Descriptor(displayName: "Move Right", shortcut: Shortcut(cmd|alt|ctrl, kVK_RightArrow), imageName: "moveRightTemplate")
        case .moveUp: return Descriptor(displayName: "Move Up", shortcut: Shortcut(cmd|alt|ctrl, kVK_UpArrow), imageName: "moveUpTemplate")
        case .moveDown: return Descriptor(displayName: "Move Down", shortcut: Shortcut(cmd|alt|ctrl, kVK_DownArrow), imageName: "moveDownTemplate")
        case .maximize: return Descriptor(displayName: "Maximize", shortcut: Shortcut(cmd|alt|ctrl, kVK_ANSI_M), imageName: "maximizeTemplate", firstInGroup: true)
        case .center: return Descriptor(displayName: "Center", shortcut: Shortcut(cmd|alt|ctrl, kVK_ANSI_C), imageName: "centerTemplate")
        case .switchDisplay: return Descriptor(displayName: "Switch Display", shortcut: Shortcut(cmd|alt|ctrl, kVK_Space), imageName: "nextDisplayTemplate", firstInGroup: true)
        }
    }

    var name: String { rawValue }
    var displayName: String { descriptor.displayName }
    var keybindingDefaults: Shortcut { descriptor.shortcut }
    var firstInGroup: Bool { descriptor.firstInGroup }
    var image: NSImage { NSImage(imageLiteralResourceName: descriptor.imageName) }
}

struct Shortcut {
    let keyCode: Int
    let modifierFlags: UInt
    
    init(_ modifierFlags: UInt, _ keyCode: Int) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }
}
