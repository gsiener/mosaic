import XCTest

// Layout.swift and WindowAction.swift are compiled straight into this bundle
// (no test host), so the tests never launch the app or touch Accessibility.

private func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    return CGRect(x: x, y: y, width: width, height: height)
}

private let full = rect(0, 0, 1, 1)
private let somewhere = rect(0.27, 0.41, 0.38, 0.22)

private func assertRect(_ actual: CGRect, _ expected: CGRect, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(actual.closeTo(expected, tolerance: 0.0001), "\(actual) is not \(expected)", file: file, line: line)
}

/// Applies the action repeatedly, feeding each result back in, like pressing the shortcut again.
private func presses(_ action: WindowAction, from start: CGRect, count: Int) -> [CGRect] {
    var current = start
    return (0..<count).map { _ in
        current = Layout.target(for: action, current: current, previous: nil)
        return current
    }
}

class LayoutTests: XCTestCase {

    // MARK: Horizontal cycles

    func testMoveLeftCyclesHalfThirdTwoThirds() {
        let steps = presses(.moveLeft, from: somewhere, count: 4)
        assertRect(steps[0], rect(0, 0, 0.5, 1))
        assertRect(steps[1], rect(0, 0, 0.33, 1))
        assertRect(steps[2], rect(0, 0, 0.66, 1))
        assertRect(steps[3], rect(0, 0, 0.5, 1))
    }

    func testMoveRightCyclesHalfThirdTwoThirds() {
        let steps = presses(.moveRight, from: somewhere, count: 4)
        assertRect(steps[0], rect(0.5, 0, 0.5, 1))
        assertRect(steps[1], rect(0.66, 0, 0.34, 1))
        assertRect(steps[2], rect(0.33, 0, 0.67, 1))
        assertRect(steps[3], rect(0.5, 0, 0.5, 1))
    }

    func testCycleMatchesWithinThreshold() {
        // A window that is "almost" left half (off by less than THRESHOLD) still advances the cycle.
        let nearlyHalf = rect(0.01, 0.005, 0.49, 0.99)
        assertRect(Layout.target(for: .moveLeft, current: nearlyHalf, previous: nil), rect(0, 0, 0.33, 1))
    }

    // MARK: Vertical cycles

    func testMoveUpAtTopCyclesHeightAndKeepsColumn() {
        let leftHalfTop = rect(0, 0, 0.5, 0.5)
        let steps = presses(.moveUp, from: leftHalfTop, count: 4)
        assertRect(steps[0], rect(0, 0, 0.5, 0.33))
        assertRect(steps[1], rect(0, 0, 0.5, 1.0))
        assertRect(steps[2], rect(0, 0, 0.5, 0.66))
        assertRect(steps[3], rect(0, 0, 0.5, 0.5))
    }

    func testMoveUpFromMiddleThirdGoesToTopThird() {
        assertRect(Layout.target(for: .moveUp, current: rect(0.5, 0.33, 0.5, 0.33), previous: nil), rect(0.5, 0, 0.5, 0.33))
    }

    func testMoveUpElsewhereSnapsToTopKeepingSize() {
        assertRect(Layout.target(for: .moveUp, current: somewhere, previous: nil), rect(0.27, 0, 0.38, 0.22))
    }

    func testMoveDownAtBottomCyclesHeightAnchoredToBottom() {
        let steps = presses(.moveDown, from: rect(0, 0.5, 1, 0.5), count: 4)
        assertRect(steps[0], rect(0, 0.67, 1, 0.33))
        assertRect(steps[1], rect(0, 0, 1, 1.0))
        assertRect(steps[2], rect(0, 0.34, 1, 0.66))
        assertRect(steps[3], rect(0, 0.5, 1, 0.5))
    }

    func testMoveDownFromTopThirdGoesToMiddleThird() {
        assertRect(Layout.target(for: .moveDown, current: rect(0, 0, 0.5, 0.33), previous: nil), rect(0, 0.33, 0.5, 0.33))
    }

    func testMoveDownElsewhereSnapsToBottomKeepingSize() {
        assertRect(Layout.target(for: .moveDown, current: somewhere, previous: nil), rect(0.27, 0.78, 0.38, 0.22))
    }

    // MARK: Center

    func testCenterCyclesLargeMediumSmall() {
        let steps = presses(.center, from: somewhere, count: 4)
        assertRect(steps[0], rect(0.1, 0.1, 0.8, 0.8))
        assertRect(steps[1], rect(0.2, 0.2, 0.6, 0.6))
        assertRect(steps[2], rect(0.33, 0.33, 0.33, 0.33))
        assertRect(steps[3], rect(0.1, 0.1, 0.8, 0.8))
    }

    // MARK: Maximize

    func testMaximizeFillsScreen() {
        assertRect(Layout.target(for: .maximize, current: somewhere, previous: nil), full)
    }

    func testMaximizeAgainRestoresFrameBeforeLastAction() {
        let history = WindowEvent(id: 1, previous: somewhere, target: full)
        assertRect(Layout.target(for: .maximize, current: full, previous: history), somewhere)
    }

    func testMaximizeWhenAlreadyFullWithoutHistoryStaysFull() {
        assertRect(Layout.target(for: .maximize, current: full, previous: nil), full)
    }

    func testMaximizeIgnoresHistoryWhenNotFull() {
        let history = WindowEvent(id: 1, previous: rect(0, 0, 0.5, 1), target: full)
        assertRect(Layout.target(for: .maximize, current: somewhere, previous: history), full)
    }

    // MARK: Switch display

    func testSwitchDisplayKeepsRelativeFrame() {
        assertRect(Layout.target(for: .switchDisplay, current: somewhere, previous: nil), somewhere)
    }
}

class WindowActionTests: XCTestCase {

    func testNamesAreStableUserDefaultsKeys() {
        // MASShortcut persists user-customized shortcuts under these keys; renaming one loses the user's binding.
        XCTAssertEqual(WindowAction.active.map(\.name),
                       ["moveLeft", "moveRight", "moveUp", "moveDown", "maximize", "center", "switchDisplay"])
    }

    func testMenuGroups() {
        XCTAssertEqual(WindowAction.active.filter(\.firstInGroup), [.moveLeft, .maximize, .switchDisplay])
    }

    func testDefaultShortcutsUseControlOptionCommand() {
        let hyper = NSEvent.ModifierFlags([.control, .option, .command]).rawValue
        for action in WindowAction.active {
            XCTAssertEqual(action.keybindingDefaults.modifierFlags, hyper, action.name)
        }
        XCTAssertEqual(Set(WindowAction.active.map(\.keybindingDefaults.keyCode)).count, WindowAction.active.count,
                       "default shortcuts must not collide")
    }
}
