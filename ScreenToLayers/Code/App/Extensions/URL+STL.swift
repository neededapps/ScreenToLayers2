
import Foundation

extension URL {
    
    internal func abreviatedContainerPath() -> String {
        let path = self.path()
        guard path.contains("Library/Containers/") else { return path }
        let pictureURLS = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)
        guard let firstPictureURL = pictureURLS.first else { return path }
        let prefix = firstPictureURL.deletingLastPathComponent().path()
        return path.replacingOccurrences(of: prefix, with: "~/")
    }
    
    internal func stopAccessingSecurityScopedResource(isEnabled: Bool) {
        guard isEnabled else { return }
        stopAccessingSecurityScopedResource()
    }
}
