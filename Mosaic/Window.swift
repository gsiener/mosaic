import Foundation
import Carbon
import Cocoa

typealias WindowId = Int

struct WindowEvent : CustomStringConvertible {
    var id: WindowId
    var previous: CGRect = CGRect.zero
    var target: CGRect = CGRect.zero
    
    var description: String {
        get {
            return "\(id): Previous: \(previous) Target: \(target)"
        }
    }
}

class Window {
    private let underlyingElement: AXUIElement
    private let screens: Screens
    
    required init(_ axUIElement: AXUIElement, screens: Screens) {
        self.underlyingElement = axUIElement
        self.screens = screens
    }
    
    static func frontmostWindow(screens: Screens) -> Window? {
        guard let frontmostApplication: NSRunningApplication = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApplication = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        let focusedAttr = NSAccessibility.Attribute.focusedWindow as CFString
        var copiedUnderlyingElement: AnyObject?
        let result: AXError = AXUIElementCopyAttributeValue(axApplication, focusedAttr, &copiedUnderlyingElement)
        if result == .success {
            if let copiedUnderlyingElement = copiedUnderlyingElement {
                return Window(copiedUnderlyingElement as! AXUIElement, screens: screens)
            }
        }
        
        return nil
    }
    
    /// Sheets, system dialogs and windows without a readable frame are left alone.
    var isAdjustable: Bool {
        return !self.isSheet() && !self.isSystemDialog() && !self.rect().isNull
    }

    func rect() -> CGRect {
        guard let position: CGPoint = getPosition(),
            let size: CGSize = getSize()
            else {
                return CGRect.null
        }
        return CGRect(x: position.x, y: position.y, width: size.width, height: size.height)
    }
    
    func normalizedRect(in screen: NSScreen) -> CGRect {
        let rect = self.rect()
        
        let originFrame = NSRectToCGRect(self.screens.originScreen.frame)
        let screenFrame = NSRectToCGRect(screen.visibleFrame)
        
        return CGRect(x: (rect.minX - screenFrame.minX) / screenFrame.width,
                      y: (rect.minY + screenFrame.maxY - originFrame.height) / screenFrame.height,
                      width: rect.width / screenFrame.width,
                      height: rect.height / screenFrame.height)
    }
    
    func adjust(to targetNormalizedRect: CGRect, on screen: NSScreen) {
        let originFrame = NSRectToCGRect(self.screens.originScreen.frame)
        let screenFrame = NSRectToCGRect(screen.visibleFrame)

        let rect = CGRect(x: screenFrame.minX + screenFrame.width * targetNormalizedRect.minX,
                          y: originFrame.height - screenFrame.maxY + screenFrame.height * targetNormalizedRect.minY,
                          width: screenFrame.width * targetNormalizedRect.width,
                          height: screenFrame.height * targetNormalizedRect.height)
        
        let currentNormalizedRect = self.normalizedRect(in: screen)
        if currentNormalizedRect.minX + targetNormalizedRect.width > 1.0 || currentNormalizedRect.minY + targetNormalizedRect.height > 1.0 {
            set(position: rect.origin)
            set(size: rect.size)
        } else {
            set(size: rect.size)
            set(position: rect.origin)
        }
    }
    
    func isSheet() -> Bool {
        return value(for: .role) == kAXSheetRole
    }
    
    func isSystemDialog() -> Bool {
        return value(for: .subrole) == kAXSystemDialogSubrole
    }
    
    func getIdentifier() -> Int? {
        if let windowInfo = CGWindowListCopyWindowInfo(.optionOnScreenOnly, 0) as? Array<Dictionary<String,Any>> {
            var pid: pid_t = 0;
            AXUIElementGetPid(self.underlyingElement, &pid);

            let rect = self.rect()
            
            let windowsOfSameApp = windowInfo.filter { (infoDict) -> Bool in
                infoDict[kCGWindowOwnerPID as String] as? pid_t == pid
            }
            
            let matchingWindows = windowsOfSameApp.filter { (infoDict) -> Bool in
                if let boundsDict = infoDict[kCGWindowBounds as String] as? NSDictionary,
                    let bounds = CGRect(dictionaryRepresentation: boundsDict) {
                    // AX and CGWindowList frames can disagree by a fraction of a point
                    return bounds.closeTo(rect, tolerance: 1.0)
                }
                return false
            }
            
            if let firstMatch = matchingWindows.first {
                return firstMatch[kCGWindowNumber as String] as? Int
            }
        }
        return nil
    }
        
    private func getPosition() -> CGPoint? {
        return self.value(for: .position)
    }
    
    private func set(position: CGPoint) {
        if let value = AXValue.from(value: position, type: .cgPoint) {
            AXUIElementSetAttributeValue(self.underlyingElement, kAXPositionAttribute as CFString, value)
        }
    }
    
    private func getSize() -> CGSize? {
        return self.value(for: .size)
    }
    
    private func set(size: CGSize) {
        if let value = AXValue.from(value: size, type: .cgSize) {
            AXUIElementSetAttributeValue(self.underlyingElement, kAXSizeAttribute as CFString, value)
        }
    }
    
    private func value<T>(for attribute: NSAccessibility.Attribute) -> T? {
        var rawValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(self.underlyingElement, attribute.rawValue as CFString, &rawValue)
        if error == .success && CFGetTypeID(rawValue) == AXValueGetTypeID() {
            return (rawValue as! AXValue).toValue()
        }
        
        return nil
    }
}

extension AXValue {
    func toValue<T>() -> T? {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        let success = AXValueGetValue(self, AXValueGetType(self), pointer)
        return success ? pointer.pointee : nil
    }
    
    static func from<T>(value: T, type: AXValueType) -> AXValue? {
        return withUnsafePointer(to: value) { AXValueCreate(type, $0) }
    }
}
