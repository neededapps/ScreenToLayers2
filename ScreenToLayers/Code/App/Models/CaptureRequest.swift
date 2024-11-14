
import Foundation

public struct CaptureRequest: Sendable, Codable, Equatable {
    
    // MARK: Initializers
    
    public init() { }
    
    // MARK: Properties
    
    public var playsSoundAtCountdown: Bool = true
    
    public var playsSoundAtCapture: Bool = true
    
    public var opensFilesAfterExport: Bool = true
    
    public var opensFolderAfterExport: Bool = true
    
    public var userExportDirectoryURL: URL?
}
