
import Foundation

// Using Swift code here to take advantage of automatic generation of localization strings.

@objc public class MASStrings: NSObject {
    
    @objc public class func spaceKeyDescription() -> String {
        return String(
            localized: "Space",
            comment: "Shortcut glyph name for SPACE key"
        )
    }
    
    @objc public class func shortcutCannotBeUsed(menuItemTitle: String) -> String {
        return String(
            localized: "This shortcut cannot be used because it is already used by the menu item ‘\(menuItemTitle)’.",
            comment: "Message for alert when shortcut is already used"
        )
    }
    
    @objc public class func combinationCannotBeUsedBecauseAlreadyUsed() -> String {
        return String(
            localized: "This combination cannot be used because it is already used by a system-wide keyboard shortcut.\nIf you really want to use this key combination, most shortcuts can be changed in System Settings.",
            comment: "Message for alert when shortcut is already used by the system"
        )
    }
    
    @objc public class func useOldShorcutButtonTitle() -> String {
        return String(
            localized: "Use Old Shortcut",
            comment: "Cancel action button for non-empty shortcut in recording state"
        )
    }
    
    @objc public class func typeNewShortcutButtonTitle() -> String {
        return String(
            localized: "Type New Shortcut",
            comment: "Non-empty shortcut button in recording state"
        )
    }
    
    @objc public class func typeShortcutButtonTitle() -> String {
        return String(
            localized: "Type Shortcut",
            comment: "Empty shortcut button in recording state"
        )
    }
    
    @objc public class func cancelButtonTitle() -> String {
        return String(
            localized: "Cancel",
            comment: "Cancel action button in recording state"
        )
    }
    
    @objc public class func recordButtonTitle() -> String {
        return String(
            localized: "Record Shortcut",
            comment: "Empty shortcut button in normal state"
        )
    }
    
    @objc public class func keyCombinationCannotBeUsed(title: String) -> String {
        return String(
            localized: "The key combination \(title) cannot be used",
            comment: "Title for alert when shortcut is already used"
        )
    }
    
    @objc public class func okButtonShortcutAlreadyUsed() -> String {
        return String(
            localized: "OK",
            comment: "Alert button when shortcut is already used"
        )
    }
}
