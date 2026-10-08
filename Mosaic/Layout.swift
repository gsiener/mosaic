import Foundation

let THRESHOLD: CGFloat = 0.02

protocol ThresholdComparable {
    func closeTo(_ b: Self, tolerance: CGFloat) -> Bool
}

extension CGRect : ThresholdComparable {
    func closeTo(_ b: CGRect, tolerance: CGFloat) -> Bool {
        return abs(b.minX - self.minX) < tolerance && abs(b.maxX - self.maxX) < tolerance && abs(b.minY - self.minY) < tolerance && abs(b.maxY - self.maxY) < tolerance
    }
}

extension CGFloat : ThresholdComparable {
    func closeTo(_ b: CGFloat, tolerance: CGFloat) -> Bool {
        return abs(b - self) < tolerance
    }
}

func cycle<T:ThresholdComparable>(through cycle:[T], current:T) -> T {
    var winningIndex = 0
    for i in 0..<cycle.count-1 {
        if cycle[i].closeTo(current, tolerance: THRESHOLD) {
            winningIndex = i+1
        }
    }
    return cycle[winningIndex]
}

/// Decides where a window should go for an action. Pure: works entirely in
/// normalized coordinates, where (0,0)-(1,1) spans a screen's visible frame
/// with y growing downward. Applying the result to a real window is Window's job.
enum Layout {
    static func target(for action: WindowAction, current: CGRect, previous: WindowEvent?) -> CGRect {
        switch action {
        case .moveLeft:
            return cycle(through: [CGRect(x:0, y:0, width:0.5, height:1.0), CGRect(x:0, y:0, width:0.33, height:1.0), CGRect(x:0, y:0, width:0.66, height:1.0)],
                         current: current)
        case .moveRight:
            return cycle(through: [CGRect(x:0.5, y:0, width:0.5, height:1.0), CGRect(x:0.66, y:0, width:0.34, height:1.0), CGRect(x:0.33, y:0, width:0.67, height:1.0)],
                         current: current)
        case .moveUp:
            return moveUp(current)
        case .moveDown:
            return moveDown(current)
        case .maximize:
            return maximize(current, previous: previous)
        case .center:
            return cycle(through: [CGRect(x:0.1, y:0.1, width:0.8, height:0.8), CGRect(x:0.2, y:0.2, width:0.6, height:0.6), CGRect(x:0.33, y:0.33, width:0.33, height:0.33)],
                         current: current)
        case .switchDisplay:
            // Same relative frame; the caller moves it to the next screen.
            return current
        }
    }

    private static func moveUp(_ current: CGRect) -> CGRect {
        var y = current.minY
        var height = current.height

        if y <= THRESHOLD {
            y = 0
            height = cycle(through: [0.5, 0.33, 1.0, 0.66], current: height)
        } else if abs(height - 0.33) <= THRESHOLD {
            y = cycle(through: [0.33, 0], current: y)
        } else {
            y = 0
        }

        return CGRect(x: current.minX, y: y, width: current.width, height: height)
    }

    private static func moveDown(_ current: CGRect) -> CGRect {
        var y = current.minY
        var height = current.height

        if abs(1.0 - (y + height)) < THRESHOLD {
            height = cycle(through: [0.5, 0.33, 1.0, 0.66], current: height)
            y = 1.0 - height
        } else if abs(height - 0.33) <= THRESHOLD {
            y = cycle(through: [0.33, 1.0 - height], current: y)
        } else {
            y = 1.0 - height
        }

        return CGRect(x: current.minX, y: y, width: current.width, height: height)
    }

    private static func maximize(_ current: CGRect, previous: WindowEvent?) -> CGRect {
        let full = CGRect(x:0.0, y:0.0, width:1.0, height:1.0)
        if full.closeTo(current, tolerance: THRESHOLD), let previous = previous {
            return previous.previous
        }
        return full
    }
}
