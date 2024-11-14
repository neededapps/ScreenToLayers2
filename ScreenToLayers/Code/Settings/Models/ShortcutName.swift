
import Foundation

public enum ShortcutName: String, Identifiable {
    case captureNow = "capture_now"
    case captureWithDelay = "capture_with_delay"
    public var id : String { rawValue }
}
