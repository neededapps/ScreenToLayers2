
import Foundation
@preconcurrency
import ScreenCaptureKit

public struct ScreenshotTarget: Sendable {
    
    // MARK: Initializers
    
    public init(
//        carbonWindows: [CarbonSendableWindow],
        shareableContent: SCShareableContent,
        shareableDisplay: SCDisplay,
        shareableDisplayIndex: Int
    ) {
//        self.carbonWindows = carbonWindows
        self.shareableContent = shareableContent
        self.shareableDisplay = shareableDisplay
        self.shareableDisplayIndex = shareableDisplayIndex
    }
    
    // MARK: Properties
    
//    public let carbonWindows: [CarbonSendableWindow]
        
    public let shareableContent: SCShareableContent
    
    public let shareableDisplay: SCDisplay
    
    public let shareableDisplayIndex: Int
    
    public var fileSuffix: String {
        guard shareableContent.displays.count > 1 else { return "" }
        return " (\(shareableDisplayIndex)"
    }
}
