
import SwiftUI
import QuartzCore

public struct ShortcutRecorderView: NSViewRepresentable {
    
    // MARK: Initialziers
    
    public init(name: ShortcutName, style: MASShortcutViewStyle) {
        self.name = name
        self.style = style
    }
    
    // MARK: Properties
    
    private var name: ShortcutName
    
    private var style: MASShortcutViewStyle
    
    // MARK: View representable
    
    public func makeNSView(context: Context) -> MASShortcutView {
        let shortcutView = MASShortcutView()
        shortcutView.style = style
        shortcutView.associatedUserDefaultsKey = name.rawValue
        return shortcutView
    }

    public func updateNSView(_ nsView: MASShortcutView, context: Context) {
        // Nothing to do
    }
}
