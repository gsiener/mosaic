import Cocoa

class Screens {
    let screens: [NSScreen]
    let originScreen: NSScreen
    
    static func detect() -> Screens? {
        guard let originScreen = NSScreen.screens.first else { return nil }
        return Screens(NSScreen.screens, originScreen)
    }
    
    init(_ screens: [NSScreen], _ originScreen: NSScreen) {
        self.screens = screens
        self.originScreen = originScreen
    }
    
    func screenContaining(_ window: Window) -> NSScreen? {
        return screens.max(by: {a, b in percentageOf(window, withinScreen: a) < percentageOf(window, withinScreen: b)})
    }
   
    func screenAfter(_ screen: NSScreen) -> NSScreen{
        guard let index = screens.firstIndex(of: screen), index + 1 < screens.count else {
            return screens[0]
        }
        return screens[index + 1]
    }
    
    private func percentageOf(_ window: Window, withinScreen screen: NSScreen) -> CGFloat {
        let rect = window.normalizedRect(in: screen)
        let intersection = rect.intersection(CGRect(x:0, y:0, width:1, height:1))
        return intersection.size.width * intersection.size.height
     }
}
