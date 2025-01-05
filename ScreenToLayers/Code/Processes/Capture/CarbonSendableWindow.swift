
import Foundation

public struct CarbonSendableWindow: Sendable, Equatable, Hashable {
    
    // MARK: Initializers
    
    public init(window: CarbonScreenshotWindow) {
        self.ownerName = window.ownerName
        self.title = window.title
        self.processID = window.processID
        self.windowID = window.windowID
        self.bounds = window.bounds
        self.level = window.level
        self.tag = window.tag
    }
    
    // MARK: Properties
    
    public let ownerName: String?
    
    public let title: String?
    
    public let processID: Int
    
    public let windowID: CGWindowID
    
    public let bounds: CGRect
    
    public let level: Int
    
    public let tag: Int
}
