
import Foundation

public struct ScreenshotRequest: Equatable, Codable, Sendable {
    
    // MARK: Initializers
    
    public init(exportDirectoryURL: URL) {
        self.exportDirectoryURL = exportDirectoryURL
    }
    
    // MARK: Properties
    
    public var exportDirectoryURL: URL
}
