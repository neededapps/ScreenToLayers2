
import Foundation
import UniformTypeIdentifiers

extension CGImage {
    
    // MARK: Export to disk
    
    public func exportPNG(to folderURL: URL, filename: String) throws {
        let type = (UTType.png.identifier as CFString)
        let fixedName = filename.hasSuffix(".png") ? filename : "\(filename).png"
        let fileURL = folderURL.appendingPathComponent(fixedName)
        try? FileManager.default.removeItem(at: fileURL)
        
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, type, 1, nil) else {
            let userInfo = [NSLocalizedDescriptionKey: "Failed to create image destination."]
            throw NSError(domain: "CGImageExportError", code: 1, userInfo: userInfo)
        }
        
        CGImageDestinationAddImage(destination, self, nil)
        if !CGImageDestinationFinalize(destination) {
            let userInfo = [NSLocalizedDescriptionKey: "Failed to finalize image export."]
            throw NSError(domain: "CGImageExportError", code: 2, userInfo: userInfo)
        }
    }
}
