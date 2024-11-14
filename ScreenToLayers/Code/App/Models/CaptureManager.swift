
import SwiftUI
import Observation

@MainActor
@Observable
public class CaptureManager {
    
    // MARK: Enumerations
    
    public enum CaptureState: String, Identifiable, CaseIterable {
        case idle = "idle"
        case count3 = "count3"
        case count2 = "count2"
        case count1 = "count1"
        case capturing = "capturing"
        case exporting = "exporting"
        
        public var id: String { rawValue }
    }
    
    // MARK: Initializers
    
    public init() {
        self.timerCountdownSound = NSSound(named: "Tink")
        self.timerCountdownSound?.volume = 0.5
        self.cameraCaptureSound = NSSound(named: "CameraCaptureSound")
        self.cameraCaptureSound?.volume = 1.0
    }
    
    // MARK: Properties
    
    public private(set) var captureState: CaptureState = .idle
    
    public var captureError: WrappedError = .none

    private var timerCountdownSound: NSSound?
    
    private var cameraCaptureSound: NSSound?
    
    // MARK: Capture process
    
    private func performCapture(request: CaptureRequest) async throws {
        guard let exportDirectoryURL = request.userExportDirectoryURL else { return }
        let scoped = exportDirectoryURL.startAccessingSecurityScopedResource()
        defer { exportDirectoryURL.stopAccessingSecurityScopedResource(isEnabled: scoped) }
        
        let exporter = ScreenshotExporter(request: ScreenshotRequest(
            exportDirectoryURL: exportDirectoryURL))
        try await exporter.captureAndExport()
        
        if request.opensFilesAfterExport {
            let urls = await exporter.exportedFileURLs
            urls.forEach { NSWorkspace.shared.open($0) }
        }
        if request.opensFolderAfterExport {
            let url = await exporter.exportedFolderURL
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    private func performFaillable(perform: @escaping () async throws -> ()) async {
        do {
            try await perform()
        } catch let error {
            captureState = .idle
            captureError = .wrapped(error)
        }
    }
    
    private func performTask(perform: @escaping () async throws -> ()) {
        Task { await performFaillable(perform: perform) }
    }
    
    // MARK: Actions
    
    public func canCapture(request: CaptureRequest) -> Bool {
        guard captureState == .idle else { return false }
        return request.userExportDirectoryURL != nil
    }
    
    public func captureScreenNow(request: CaptureRequest) {
        guard canCapture(request: request) else { return }
        captureState = .capturing
        
        performTask {
            if request.playsSoundAtCapture {
                self.cameraCaptureSound?.play()
            }
            
            self.captureState = .exporting
            try await self.performCapture(request: request)
            self.captureState = .idle
        }
    }
    
    public func captureScreenWithDelay(request: CaptureRequest) {
        guard canCapture(request: request) else { return }
        captureState = .count3
        
        performTask {
            if request.playsSoundAtCountdown {
                self.timerCountdownSound?.play()
            }
            try await Task.sleep(for: .seconds(1))
            self.captureState = .count2
            if request.playsSoundAtCountdown {
                self.timerCountdownSound?.play()
            }
            try await Task.sleep(for: .seconds(1))
            self.captureState = .count1
            if request.playsSoundAtCountdown {
                self.timerCountdownSound?.play()
            }
            try await Task.sleep(for: .seconds(1))
            self.captureState = .capturing
            if request.playsSoundAtCapture {
                self.cameraCaptureSound?.play()
            }
            
            self.captureState = .exporting
            try await self.performCapture(request: request)
            self.captureState = .idle
        }
    }
}
