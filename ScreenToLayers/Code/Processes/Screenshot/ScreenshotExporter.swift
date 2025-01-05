
// Notes:
//
// To reset Screen Recording access for a specific app, use the following command:
// tccutil reset ScreenCapture com.jeremyvizzini.screentolayers.osx
// tccutil reset Microphone com.jeremyvizzini.screentolayers.osx
//
// If you want to reset permissions for all apps, use:
// tccutil reset ScreenCapture
// tccutil reset Microphone

import Foundation
@preconcurrency
import ScreenCaptureKit

public actor ScreenshotExporter {
    
    // MARK: Initializers
    
    public init(request: ScreenshotRequest) {
        self.request = request
        self.exportedFolderURL = request.exportDirectoryURL
        self.shooter = ScreenCaptureKitShooter()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        self.dateDescription = dateFormatter.string(from: .now)
    }
    
    // MARK: Properties
    
    public let request: ScreenshotRequest
    
    public private(set) var isExporting: Bool = false
    
    public private(set) var exportedFileURLs: [URL] = []
    
    public private(set) var exportedFolderURL: URL
    
    private var shooter: ScreenCaptureKitShooter
    
    private var dateDescription: String
    
    // MARK: Process display
    
    public func isWindow(_ window: SCWindow, above subWindow: SCWindow) -> Bool {
        let listOptions: CGWindowListOption = [.optionOnScreenOnly, .optionOnScreenAboveWindow]
        let infoList = CGWindowListCopyWindowInfo(listOptions, window.windowID)
        return ((infoList as? [[CFString: Any]]) ?? []).contains { dict in
            (subWindow.windowID == ((dict[kCGWindowNumber] as? Int) ?? 0))
        }
    }
    
    private func sortDisplayedWindows(windows: [SCWindow]) -> [SCWindow] {
        let sortedLayerLevels = Set(windows.map({ $0.windowLayer })).sorted()
        return sortedLayerLevels.reduce(into: []) { result, layer in
            let windowsOnLevel = windows.filter({ $0.windowLayer == layer })
            let sortedWindows = windowsOnLevel.sorted { isWindow($0, above: $1) }
            result.append(contentsOf: sortedWindows)
        }
    }
    
    private func performExport(writer: PSDWriter, filename: String) async throws -> URL {
        try FileManager.default.createDirectory(
            at: exportedFolderURL, withIntermediateDirectories: true)
        
        let fileURL = exportedFolderURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
        writer.write(toFileURL: fileURL)
        return fileURL
    }
    
    private func processTarget(_ target: ScreenshotTarget) async throws {
        guard !target.shareableDisplay.frame.isEmpty else { return }
        let previewElement = try await shooter.shootScreenElement(display: target.shareableDisplay)
        let writer = PSDWriter(size: previewElement.scaledContentRect.size)
        writer.setPreview(previewElement.cgImage)
        
        for window in sortDisplayedWindows(windows: target.shareableContent.windows) {
            let displayFrame = target.shareableDisplay.frame
            guard window.isOnScreen && window.frame.intersects(displayFrame) else { continue }
            guard window.frame.width > 2 && window.frame.height > 2 else { continue }
            
            let isSystemElement = false
                || (window.windowLayer < CGWindowLevelForKey(.desktopWindow))
                || (window.windowLayer == CGWindowLevelForKey(.mainMenuWindow))
                || (window.windowLayer == CGWindowLevelForKey(.statusWindow))
            let screenshotElement: ScreenCaptureKitElement? = (isSystemElement)
                ? try? await shooter.shootSystemElement(display: target.shareableDisplay, window: window)
                : try? await shooter.shootWindowElement(display: target.shareableDisplay, window: window)
            if let element = screenshotElement {
                let offset = element.scaledContentRect.origin
                let layerName = element.displayedName
                writer.add(element.cgImage, name: layerName, offset: offset)
            }
        }
        
        if let element = try? await shooter.shootCursorElement(display: target.shareableDisplay) {
            let offset = element.scaledContentRect.origin
            let layerName = element.displayedName
            writer.add(element.cgImage, name: layerName, offset: offset)
        }
        
        let filename = "\(dateDescription)\(target.fileSuffix).psd"
        let fileURL = try await performExport(writer: writer, filename: filename)
        exportedFileURLs.append(fileURL)
    }
    
    private func processDisplaysSeparately() async throws {
//        let windows = CarbonScreenshotWindow.sharedWindows()
//            .map { CarbonSendableWindow(window: $0) }
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true)
        
        for (index, display) in content.displays.enumerated() {
            guard !display.frame.isEmpty else { return }
            try await processTarget(ScreenshotTarget(
//                carbonWindows: windows,
                shareableContent: content,
                shareableDisplay: display,
                shareableDisplayIndex: index
            ))
        }
    }
    
    // MARK: Screenshot process
    
    public func captureAndExport() async throws {
        guard !isExporting else { return }
        do {
            isExporting = true
            try await processDisplaysSeparately()
            try await shooter.stopShooting()
            isExporting = false
        } catch let error {
            isExporting = false
            try await shooter.stopShooting()
            print(error.localizedDescription)
            throw error
        }
    }
}
