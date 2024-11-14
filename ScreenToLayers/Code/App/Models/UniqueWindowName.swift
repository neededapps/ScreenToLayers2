
import Cocoa
import SwiftUI

public enum UniqueWindowName: String {
    case presentationWindow = "presentation_window"
}

extension OpenWindowAction {
    
    // MARK: Open window
    
    public func callAsFunction(name: UniqueWindowName) {
        callAsFunction(id: name.rawValue, value: name.rawValue)
    }
}

extension DismissWindowAction {
    
    // MARK: Dismiss action
    
    public func callAsFunction(name: UniqueWindowName) {
        callAsFunction(id: name.rawValue, value: name.rawValue)
    }
}

extension WindowGroup {
    
    // MARK: Window group
    
    public init<C: View>(
        name: UniqueWindowName, content: @escaping () -> C
    ) where Content == PresentedWindowContent<String, C> {
        self.init(
            id: name.rawValue,
            content: { _ in content() },
            defaultValue: { name.rawValue }
        )
    }
}
